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

enum LedgerStatus { initial, loading, success, failure }

class LedgerState extends Equatable {
  const LedgerState({
    this.status = LedgerStatus.initial,
    this.ledgerReport,
    this.timePeriods = const [],
    this.message,
  });

  final LedgerStatus status;
  final List<TimePeriod> timePeriods;
  final String? message;
  final LedgerReport? ledgerReport;

  LedgerState copyWith({
    LedgerStatus? status,
    List<TimePeriod>? timePeriods,
    String? message,
    LedgerReport? ledgerReport,
  }) {
    return LedgerState(
      status: status ?? this.status,
      timePeriods: timePeriods ?? this.timePeriods,
      ledgerReport: ledgerReport ?? this.ledgerReport,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, ledgerReport, timePeriods];

  @override
  String toString() =>
      '$status { title: ${ledgerReport?.title}, '
      'message $message}';
}
