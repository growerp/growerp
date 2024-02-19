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
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

part 'ledger_event.dart';
part 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc(this.restClient) : super(const LedgerState()) {
    on<LedgerFetch>(_onLedgerFetch);
    on<LedgerCalculate>(_onLedgerCalculate);
    on<LedgerTimePeriods>(_onLedgerTimePeriods);
  }

  final RestClient restClient;

  Future<LedgerReport> callApi(ReportType reportType,
      {String periodName = ''}) async {
    switch (reportType) {
      case ReportType.ledger:
        return await restClient.getLedger();
      case ReportType.sheet:
        return await restClient.getBalanceSheet(periodName: periodName);
      case ReportType.summary:
        return await restClient.getBalanceSummary(periodName: periodName);
      default:
        // ignore: null_argument_to_non_null_type
        return Future.value(null);
    }
  }

  Future<void> _onLedgerFetch(
    LedgerFetch event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: LedgerStatus.loading));

      if (state.timePeriods.isEmpty) {
        add(const LedgerTimePeriods());
      }

      final compResult =
          await callApi(event.reportType, periodName: event.periodName);

      return emit(state.copyWith(
        status: LedgerStatus.success,
        ledgerReport: compResult,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LedgerStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onLedgerTimePeriods(
    LedgerTimePeriods event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      TimePeriods result = await restClient.getTimePeriod();
      return emit(state.copyWith(
        timePeriods: result.timePeriods,
        status: LedgerStatus.success,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LedgerStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onLedgerCalculate(
    LedgerCalculate event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LedgerStatus.loading));
      await restClient.calculateLedger();
      return emit(state.copyWith(status: LedgerStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LedgerStatus.failure, message: getDioError(e)));
    }
  }
}
