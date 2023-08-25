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
  String toString() => '$status { title: ${ledgerReport?.title}, '
      'message $message}';
}
