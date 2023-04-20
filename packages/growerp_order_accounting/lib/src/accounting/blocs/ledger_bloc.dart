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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_core/growerp_core.dart';

import '../accounting.dart';

part 'ledger_event.dart';
part 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc(this.repos) : super(const LedgerState()) {
    on<LedgerFetch>(_onLedgerFetch);
  }

  final AccountingAPIRepository repos;

  Future<ApiResult<LedgerReport>> callApi(ReportType reportType,
      {String periodName = ''}) async {
    switch (reportType) {
      case ReportType.ledger:
        return await repos.getLedger();
      case ReportType.sheet:
        return await repos.getBalanceSheet(periodName);
      case ReportType.summary:
        return await repos.getBalanceSummary(periodName);
      default:
        // ignore: null_argument_to_non_null_type
        return Future.value(null);
    }
  }

  Future<void> _onLedgerFetch(
    LedgerFetch event,
    Emitter<LedgerState> emit,
  ) async {
    // start from record zero for initial and refresh
    emit(state.copyWith(status: LedgerStatus.loading));
    final compResult =
        await callApi(event.reportType, periodName: event.periodName);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: LedgerStatus.success,
              ledgerReport: data,
            ),
        failure: (error) => state.copyWith(
            status: LedgerStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}
