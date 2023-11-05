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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';

import 'models.dart';

part 'ledger_report_model.freezed.dart';
part 'ledger_report_model.g.dart';

@freezed
class LedgerReport with _$LedgerReport {
  LedgerReport._();
  factory LedgerReport({
    Company? company,
    @Default('') String title,
    TimePeriod? period,
    DateTime? printDate,
    @Default([]) List<GlAccount> glAccounts,
  }) = _LedgerReport;

  factory LedgerReport.fromJson(Map<String, dynamic> json) =>
      _$LedgerReportFromJson(json['ledgerReport'] ?? json);
}
