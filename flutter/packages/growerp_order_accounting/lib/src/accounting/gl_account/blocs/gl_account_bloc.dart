import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'gl_account_event.dart';
part 'gl_account_state.dart';

const throttleDuration = Duration(milliseconds: 100);
const searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> glAccountDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

EventTransformer<GlAccountSearchChanged> glAccountSearchDebounce() {
  return (events, mapper) {
    // Empty string (clear) fires immediately; strings >=3 chars are debounced;
    // 1-2 char strings are ignored.
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class GlAccountBloc extends Bloc<GlAccountEvent, GlAccountState> {
  GlAccountBloc(this.restClient) : super(const GlAccountState()) {
    on<GlAccountFetch>(
      _onGlAccountFetch,
      transformer: glAccountDroppable(throttleDuration),
    );
    on<GlAccountSearchChanged>(
      _onGlAccountSearchChanged,
      transformer: glAccountSearchDebounce(),
    );
    on<GlAccountUpdate>(_onGlAccountUpdate);
    on<GlAccountClassesFetch>(_onGlAccountClassesFetch);
    on<GlAccountTypesFetch>(_onGlAccountTypesFetch);
    on<GlAccountUpload>(_onGlAccountUpload);
    on<GlAccountDownload>(_onGlAccountDownload);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onGlAccountSearchChanged(
    GlAccountSearchChanged event,
    Emitter<GlAccountState> emit,
  ) async {
    await _onGlAccountFetch(
      GlAccountFetch(
        refresh: true,
        searchString: event.searchString,
        limit: event.limit,
        trialBalance: event.trialBalance,
      ),
      emit,
    );
  }

  Future<void> _onGlAccountFetch(
    GlAccountFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    late List<GlAccount> current;
    if (state.status == GlAccountStatus.initial ||
        event.refresh ||
        event.searchString != '' ||
        event.trialBalance) {
      start = 0;
      current = [];
      // Clear the displayed list immediately so stale results don't show
      // while the backend request is in-flight.
      emit(
        state.copyWith(
          status: GlAccountStatus.loading,
          glAccounts: [],
          hasReachedMax: false,
        ),
      );
    } else {
      start = state.glAccounts.length;
      current = List.of(state.glAccounts);
    }

    try {
      final glAccounts = await restClient.getGlAccount(
        start: start,
        limit: event.limit,
        searchString: event.searchString,
        trialBalance: event.trialBalance,
      );
      glAccounts.glAccounts.isEmpty
          ? emit(
              state.copyWith(
                hasReachedMax: true,
                status: GlAccountStatus.success,
                glAccounts: current,
              ),
            )
          : emit(
              state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: current..addAll(glAccounts.glAccounts),
                hasReachedMax: glAccounts.glAccounts.length < event.limit,
              ),
            );
    } catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onGlAccountUpdate(
    GlAccountUpdate event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.glAccountLoading));
      List<GlAccount> glAccounts = List.from(state.glAccounts);
      if (event.glAccount.glAccountId != null) {
        GlAccount compResult = await restClient.updateGlAccount(
          glAccount: event.glAccount,
        );
        int index = glAccounts.indexWhere(
          (element) => element.glAccountId == event.glAccount.glAccountId,
        );
        glAccounts[index] = compResult;
        return emit(
          state.copyWith(
            status: GlAccountStatus.success,
            glAccounts: glAccounts,
            message: 'glAccountUpdateSuccess:${event.glAccount.accountName}',
          ),
        );
      } else {
        // add
        GlAccount compResult = await restClient.createGlAccount(
          glAccount: event.glAccount,
        );
        glAccounts.insert(0, compResult);
        return emit(
          state.copyWith(
            status: GlAccountStatus.success,
            glAccounts: glAccounts,
            message: 'glAccountAddSuccess:${event.glAccount.accountName}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onGlAccountClassesFetch(
    GlAccountClassesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      AccountClasses result = await restClient.getAccountClass(
        searchString: event.searchString,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          accountClasses: List.of(result.accountClasses),
          status: GlAccountStatus.success,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onGlAccountTypesFetch(
    GlAccountTypesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      AccountTypes result = await restClient.getAccountType(
        searchString: event.searchString,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          accountTypes: List.of(result.accountTypes),
          status: GlAccountStatus.success,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onGlAccountUpload(
    GlAccountUpload event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));
      List<GlAccount> glAccounts = [];
      final result = fast_csv.parse(event.file);
      // import csv into glAccounts
      for (final row in result) {
        if (row == result.first || row[0] == "        ") continue;
        glAccounts.add(
          GlAccount(
            accountCode: row[0],
            accountName: row[1],
            isDebit: row[2] == 'true' ? true : false,
            accountClass: row[3] != ''
                ? AccountClass(description: row[3])
                : null,
            accountType: row[4] != '' ? AccountType(description: row[4]) : null,
            postedBalance: row[5].isNotEmpty ? Decimal.parse(row[5]) : null,
          ),
        );
      }

      await restClient.importGlAccounts(glAccounts);
      return emit(
        state.copyWith(
          status: GlAccountStatus.success,
          glAccounts: state.glAccounts,
          message: 'glAccountUploadSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onGlAccountDownload(
    GlAccountDownload event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));
      await restClient.exportGlAccounts();
      return emit(
        state.copyWith(
          status: GlAccountStatus.success,
          glAccounts: state.glAccounts,
          message:
              "The request is scheduled and the email will be sent shortly",
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
