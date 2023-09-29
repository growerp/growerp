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
    json.decode(str)["timeEntries"].map((x) => TimeEntry.fromJson(x)));

@freezed
class TimeEntry with _$TimeEntry {
  TimeEntry._();
  factory TimeEntry({
    String? timeEntryId,
    String? taskId,
    String? partyId,
    Decimal? hours,
    String? comments,
    @DateTimeConverter() DateTime? date,
  }) = _TimeEntry;

  factory TimeEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryFromJson(json);
}
