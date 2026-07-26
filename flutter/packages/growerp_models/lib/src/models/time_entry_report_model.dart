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
