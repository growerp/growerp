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

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../growerp_models.dart';

part 'time_entry_model.freezed.dart';
part 'time_entry_model.g.dart';

TimeEntry timeEntryFromJson(String str) =>
    TimeEntry.fromJson(json.decode(str)["timeEntry"]);
String timeEntryToJson(TimeEntry data) =>
    // ignore: prefer_interpolation_to_compose_strings
    '{"timeEntry":' + json.encode(data.toJson()) + "}";

List<TimeEntry> timeEntriesFromJson(String str) => List<TimeEntry>.from(
  json.decode(str)["timeEntries"].map((x) => TimeEntry.fromJson(x)),
);

@freezed
abstract class TimeEntry with _$TimeEntry {
  TimeEntry._();
  factory TimeEntry({
    String? timeEntryId,
    String? activityId,
    String? partyId,
    Decimal? hours,
    String? comments,
    @DateTimeConverter() DateTime? date,
    // approval workflow: 'inProcess' (default) -> 'approved'
    String? status,
    // set when billed to the client / self-billed to the assistant
    String? invoiceId,
    String? vendorInvoiceId,
  }) = _TimeEntry;

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json['timeEntry'] ?? json);
}
