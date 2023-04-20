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

enum ReportType { ledger, sheet, summary }

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
