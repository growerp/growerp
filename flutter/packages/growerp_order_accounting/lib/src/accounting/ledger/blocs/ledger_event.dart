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

part of 'ledger_bloc.dart';

enum ReportType { ledger, sheet, summary, revenueExpense }

abstract class LedgerEvent extends Equatable {
  const LedgerEvent();
  @override
  List<Object> get props => [];
}

class LedgerFetch extends LedgerEvent {
  const LedgerFetch(this.reportType, {this.periodName = ''});
  final ReportType reportType;
  final String periodName;
  @override
  List<Object> get props => [reportType, periodName];
}

class LedgerTimePeriods extends LedgerEvent {
  final String periodType;

  const LedgerTimePeriods({this.periodType = 'Y'});
}

class LedgerTimePeriodsUpdate extends LedgerEvent {
  final bool? createNext;
  final bool? createPrevious;
  final bool? delete;
  final String timePeriodId;
  final String? timePeriodName;

  const LedgerTimePeriodsUpdate({
    this.createNext,
    this.createPrevious,
    this.delete,
    required this.timePeriodId,
    this.timePeriodName,
  });
}

class LedgerTimePeriodClose extends LedgerEvent {
  final String timePeriodId;
  final String? timePeriodName;

  const LedgerTimePeriodClose(this.timePeriodId, {this.timePeriodName});
}

class LedgerCalculate extends LedgerEvent {}
