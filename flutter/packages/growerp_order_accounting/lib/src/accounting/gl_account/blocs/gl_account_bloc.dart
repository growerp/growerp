/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models/growerp_models.dart';

part 'gl_account_event.dart';
part 'gl_account_state.dart';

const _glAccountLimit = 20;

EventTransformer<E> glAccountDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GlAccountBloc extends Bloc<GlAccountEvent, GlAccountState> {
  GlAccountBloc(this.restClient) : super(const GlAccountState()) {
    on<GlAccountFetch>(_onGlAccountFetch,
        transformer: glAccountDroppable(const Duration(milliseconds: 100)));
    on<GlAccountUpdate>(_onGlAccountUpdate);
    on<AccountClassesFetch>(_onAccountClassesFetch);
    on<AccountTypesFetch>(_onAccountTypesFetch);
    on<GlAccountUpload>(_onGlAccountUpload);
    on<GlAccountDownload>(_onGlAccountDownload);
  }

  final RestClient restClient;

  Future<void> _onGlAccountFetch(
    GlAccountFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));
      // start from record zero for initial and refresh
      GlAccounts compResult = await restClient.getGlAccount(
        searchString: event.searchString,
        start: 0,
        limit: event.limit ?? _glAccountLimit,
      );
      return emit(state.copyWith(
        status: GlAccountStatus.success,
        glAccounts: compResult.glAccounts,
        hasReachedMax:
            compResult.glAccounts.length < _glAccountLimit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: getDioError(e)));
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
          message: getDioError(e)));
    }
  }

  Future<void> _onAccountClassesFetch(
    AccountClassesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));
      AccountClasses result = await restClient.getAccountClass();
      return emit(state.copyWith(
          accountClasses: result.accountClasses,
          status: GlAccountStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onAccountTypesFetch(
    AccountTypesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GlAccountStatus.loading));

      AccountTypes result = await restClient.getAccountType();
      return emit(state.copyWith(
          accountTypes: result.accountTypes, status: GlAccountStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: GlAccountStatus.failure,
          glAccounts: [],
          message: getDioError(e)));
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
          message: getDioError(e)));
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
          message: getDioError(e)));
    }
  }
}
