/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

part 'ledger_event.dart';
part 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc(this.restClient) : super(const LedgerState()) {
    on<LedgerFetch>(_onLedgerFetch);
    on<LedgerCalculate>(_onLedgerCalculate);
    on<LedgerTimePeriods>(_onLedgerTimePeriods);
    on<LedgerTimePeriodsUpdate>(_onLedgerTimePeriodsUpdate);
    on<LedgerTimePeriodClose>(_onLedgerTimePeriodClose);
  }

  final RestClient restClient;

  Future<void> _onLedgerFetch(
    LedgerFetch event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: LedgerStatus.loading));
      String periodType = 'Y', year = DateTime.now().year.toString();
      // get periodType from periodname
      if (event.periodName.contains('q')) {
        periodType = 'Q';
      } else if (event.periodName.contains('m')) {
        periodType = 'M';
      } else {
        periodType = 'Y';
      }
      if (periodType != 'Y') {
        year = event.periodName.substring(1, 5);
      } else {
        year = ''; // get all years
      }
      final TimePeriods timePeriods = await restClient.getTimePeriod(
        year: year,
        periodType: periodType,
      );

      late final LedgerReport result;
      switch (event.reportType) {
        case ReportType.ledger:
          result = await restClient.getLedger();
        case ReportType.sheet:
          result = await restClient.getBalanceSheet(
            periodName: event.periodName,
          );
        case ReportType.summary:
          result = await restClient.getBalanceSummary(
            periodName: event.periodName,
          );
        case ReportType.revenueExpense:
          result = await restClient.getOperatingRevenueExpenseChart(
            periodName: event.periodName,
          );
      }

      return emit(
        state.copyWith(
          status: LedgerStatus.success,
          ledgerReport: result,
          timePeriods: timePeriods.timePeriods,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLedgerTimePeriods(
    LedgerTimePeriods event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      TimePeriods result = await restClient.getTimePeriod(
        periodType: event.periodType,
      );
      return emit(
        state.copyWith(
          timePeriods: result.timePeriods,
          status: LedgerStatus.success,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLedgerTimePeriodsUpdate(
    LedgerTimePeriodsUpdate event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      TimePeriods result = await restClient.updateTimePeriod(
        timePeriodId: event.timePeriodId,
        createNext: event.createNext,
        createPrevious: event.createPrevious,
        delete: event.delete,
      );
      return emit(
        state.copyWith(
          timePeriods: result.timePeriods,
          status: LedgerStatus.success,
          message: 'timePeriodUpdateSuccess:${event.timePeriodName ?? ''}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLedgerTimePeriodClose(
    LedgerTimePeriodClose event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      TimePeriods result = await restClient.closeTimePeriod(
        timePeriodId: event.timePeriodId,
      );
      return emit(
        state.copyWith(
          timePeriods: result.timePeriods,
          status: LedgerStatus.success,
          message: 'timePeriodCloseSuccess:${event.timePeriodName ?? ''}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLedgerCalculate(
    LedgerCalculate event,
    Emitter<LedgerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LedgerStatus.loading));
      await restClient.calculateLedger();
      return emit(
        state.copyWith(
          status: LedgerStatus.success,
          message:
              "Re-calculation ledger summaries started in the background....",
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LedgerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
