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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_entry_report_model.freezed.dart';
part 'time_entry_report_model.g.dart';

/// Hours summary for a single assistant (party) as returned by the
/// TimeEntryReport backend service.
@freezed
abstract class TimeEntryReportItem with _$TimeEntryReportItem {
  factory TimeEntryReportItem({
    String? partyId,
    String? pseudoId,
    String? firstName,
    String? lastName,
    Decimal? inProcessHours,
    Decimal? approvedHours,
    Decimal? invoicedHours,
  }) = _TimeEntryReportItem;
  TimeEntryReportItem._();

  factory TimeEntryReportItem.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryReportItemFromJson(json);
}

@freezed
abstract class TimeEntryReport with _$TimeEntryReport {
  factory TimeEntryReport({
    @Default([]) List<TimeEntryReportItem> reportItems,
  }) = _TimeEntryReport;
  TimeEntryReport._();

  factory TimeEntryReport.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryReportFromJson(json);
}
