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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_rest/growerp_rest.dart';
import '../../accounting.dart';

part 'gl_account_event.dart';
part 'gl_account_state.dart';

const _glAccountLimit = 20;

EventTransformer<E> glAccountDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GlAccountBloc extends Bloc<GlAccountEvent, GlAccountState> {
  GlAccountBloc(this.repos) : super(const GlAccountState()) {
    on<GlAccountFetch>(_onGlAccountFetch,
        transformer: glAccountDroppable(const Duration(milliseconds: 100)));
    on<GlAccountUpdate>(_onGlAccountUpdate);
    on<AccountClassesFetch>(_onAccountClassesFetch);
    on<AccountTypesFetch>(_onAccountTypesFetch);
    on<GlAccountUpload>(_onGlAccountUpload);
    on<GlAccountDownload>(_onGlAccountDownload);
  }

  final AccountingAPIRepository repos;
  Future<void> _onGlAccountFetch(
    GlAccountFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    emit(state.copyWith(status: GlAccountStatus.loading));
    // start from record zero for initial and refresh
    if (state.status == GlAccountStatus.initial || event.refresh) {
      ApiResult<List<GlAccount>> compResult = await repos.getGlAccount(
        searchString: event.searchString,
        start: 0,
        limit: event.limit ?? _glAccountLimit,
      );
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: data,
                hasReachedMax: data.length < _glAccountLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: GlAccountStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<GlAccount>> compResult = await repos.getGlAccount(
        searchString: event.searchString,
        limit: event.limit ?? _glAccountLimit,
      );
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: data,
                hasReachedMax: data.length < _glAccountLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: GlAccountStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search
    ApiResult<List<GlAccount>> compResult = await repos.getGlAccount(
      searchString: event.searchString,
      start: state.glAccounts.length,
      limit: event.limit ?? _glAccountLimit,
    );
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: GlAccountStatus.success,
              glAccounts: List.of(state.glAccounts)..addAll(data),
              hasReachedMax: data.length < _glAccountLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: GlAccountStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onGlAccountUpdate(
    GlAccountUpdate event,
    Emitter<GlAccountState> emit,
  ) async {
    emit(state.copyWith(status: GlAccountStatus.glAccountLoading));
    List<GlAccount> glAccounts = List.from(state.glAccounts);
    if (event.glAccount.glAccountId != null) {
      ApiResult<GlAccount> compResult =
          await repos.updateGlAccount(event.glAccount);
      return emit(compResult.when(
          success: (data) {
            int index = glAccounts.indexWhere((element) =>
                element.glAccountId == event.glAccount.glAccountId);
            glAccounts[index] = data;
            return state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: glAccounts,
                message: "glAccount ${event.glAccount.accountName} updated");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: GlAccountStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<GlAccount> compResult =
          await repos.createGlAccount(event.glAccount);
      return emit(compResult.when(
          success: (data) {
            glAccounts.insert(0, data);
            return state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: glAccounts,
                message: "glAccount ${event.glAccount.accountName} added");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: GlAccountStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onAccountClassesFetch(
    AccountClassesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    emit(state.copyWith(status: GlAccountStatus.loading));

    ApiResult<List<AccountClass>> periodResult = await repos.getAccountClass();
    return emit(periodResult.when(
        success: (data) => state.copyWith(
            accountClasses: data, status: GlAccountStatus.success),
        failure: (error) => state.copyWith(
            status: GlAccountStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onAccountTypesFetch(
    AccountTypesFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    emit(state.copyWith(status: GlAccountStatus.loading));

    ApiResult<List<AccountType>> periodResult = await repos.getAccountType();
    return emit(periodResult.when(
        success: (data) =>
            state.copyWith(accountTypes: data, status: GlAccountStatus.success),
        failure: (error) => state.copyWith(
            status: GlAccountStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onGlAccountUpload(
    GlAccountUpload event,
    Emitter<GlAccountState> emit,
  ) async {
    emit(state.copyWith(status: GlAccountStatus.loading));
    List<GlAccount> glAccounts = [];
    final result = fast_csv.parse(event.file);
    // import csv into glAccounts
    for (final row in result) {
      if (row == result.first) continue;
      glAccounts.add(GlAccount(
          accountCode: row[0],
          accountName: row[1],
          accountClass: row[2] != '' ? AccountClass(description: row[2]) : null,
          accountType: row[3] != '' ? AccountType(description: row[3]) : null,
          postedBalance: row[4] != '' ? Decimal.parse(row[4]) : null));
    }

    ApiResult<String> compResult = await repos.importGlAccounts(glAccounts);
    return emit(compResult.when(
        success: (data) {
          return state.copyWith(
              status: GlAccountStatus.success,
              glAccounts: state.glAccounts,
              message: data);
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: GlAccountStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onGlAccountDownload(
    GlAccountDownload event,
    Emitter<GlAccountState> emit,
  ) async {
    emit(state.copyWith(status: GlAccountStatus.loading));
    ApiResult<String> compResult = await repos.exportGlAccounts();
    return emit(compResult.when(
        success: (data) {
          return state.copyWith(
              status: GlAccountStatus.success,
              glAccounts: state.glAccounts,
              message:
                  "The request is scheduled and the email will be sent shortly");
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: GlAccountStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}
