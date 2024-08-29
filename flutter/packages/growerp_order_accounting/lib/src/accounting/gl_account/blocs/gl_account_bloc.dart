import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'gl_account_event.dart';
part 'gl_account_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> glAccountDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GlAccountBloc extends Bloc<GlAccountEvent, GlAccountState> {
  GlAccountBloc(this.restClient) : super(const GlAccountState()) {
    on<GlAccountFetch>(_onGlAccountFetch,
        transformer: glAccountDroppable(throttleDuration));
    on<GlAccountUpdate>(_onGlAccountUpdate);
    on<GlAccountClassesFetch>(_onGlAccountClassesFetch);
    on<GlAccountTypesFetch>(_onGlAccountTypesFetch);
    on<GlAccountUpload>(_onGlAccountUpload);
    on<GlAccountDownload>(_onGlAccountDownload);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onGlAccountFetch(
    GlAccountFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    late List<GlAccount> current;
    if (state.status == GlAccountStatus.initial ||
        event.refresh ||
        event.searchString != '' ||
        event.trialBalance) {
      start = 0;
      current = [];
    } else {
      start = state.glAccounts.length;
      current = List.of(state.glAccounts);
    }

    try {
      final glAccounts = await restClient.getGlAccount(
          start: start,
          limit: event.limit,
          searchString: event.searchString,
          trialBalance: event.trialBalance);
      glAccounts.glAccounts.isEmpty
          ? emit(state.copyWith(
              hasReachedMax: true, status: GlAccountStatus.success))
          : emit(
              state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: current..addAll(glAccounts.glAccounts),
                hasReachedMax: glAccounts.glAccounts.length < event.limit,
              ),
            );
    } catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure, message: await getDioError(e)));
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
        GlAccount compResult =
            await restClient.updateGlAccount(glAccount: event.glAccount);
        int index = glAccounts.indexWhere(
            (element) => element.glAccountId == event.glAccount.glAccountId);
        glAccounts[index] = compResult;
        return emit(state.copyWith(
            status: GlAccountStatus.success,
            glAccounts: glAccounts,
            message: "glAccount ${event.glAccount.accountName} updated"));
      } else {
        // add
        GlAccount compResult =
            await restClient.createGlAccount(glAccount: event.glAccount);
        glAccounts.insert(0, compResult);
        return emit(state.copyWith(
            status: GlAccountStatus.success,
            glAccounts: glAccounts,
            message: "glAccount ${event.glAccount.accountName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onGlAccountClassesFetch(
    GlAccountClassesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      AccountClasses result = await restClient.getAccountClass(
          searchString: event.searchString, limit: event.limit);
      return emit(state.copyWith(
          accountClasses: List.of(result.accountClasses),
          status: GlAccountStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onGlAccountTypesFetch(
    GlAccountTypesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      AccountTypes result = await restClient.getAccountType(
          searchString: event.searchString, limit: event.limit);
      return emit(state.copyWith(
          accountTypes: List.of(result.accountTypes),
          status: GlAccountStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e)));
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
        if (row == result.first) continue;
        glAccounts.add(GlAccount(
            accountCode: row[0],
            accountName: row[1],
            accountClass:
                row[2] != '' ? AccountClass(description: row[2]) : null,
            accountType: row[3] != '' ? AccountType(description: row[3]) : null,
            postedBalance: row[4] != '' ? Decimal.parse(row[4]) : null));
      }

      String compResult = await restClient.importGlAccounts(glAccounts);
      return emit(state.copyWith(
          status: GlAccountStatus.success,
          glAccounts: state.glAccounts,
          message: compResult));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onGlAccountDownload(
    GlAccountDownload event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));
      await restClient.exportGlAccounts();
      return emit(state.copyWith(
          status: GlAccountStatus.success,
          glAccounts: state.glAccounts,
          message:
              "The request is scheduled and the email will be sent shortly"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: await getDioError(e)));
    }
  }
}
