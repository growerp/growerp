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

import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_item_model.freezed.dart';
part 'calendar_item_model.g.dart';

/// Where an item of the in-app calendar comes from.
enum CalendarItemSource {
  @JsonValue('CALENDAR')
  calendar,
  @JsonValue('ACTIVITY')
  activity,
  @JsonValue('SOCIAL_POST')
  socialPost,
}

/// One entry of the in-app calendar: an event of the connected calendar, a
/// GrowERP activity, or a social post (backend get#CalendarItems).
@freezed
abstract class CalendarItem extends Equatable with _$CalendarItem {
  const CalendarItem._();
  const factory CalendarItem({
    @Default('') String itemId,
    CalendarItemSource? source,
    @Default('') String calendarName,
    @Default('') String title,
    @Default('') String description,

    /// yyyy-MM-dd when [allDay], else an ISO date-time; null for a backlog post
    String? start,

    /// exclusive, same format as [start]
    String? end,
    @Default(false) bool allDay,
    String? activityId,
    String? postId,
    String? statusId,
    String? platform,
    String? publishError,
  }) = _CalendarItem;

  factory CalendarItem.fromJson(Map<String, dynamic> json) =>
      _$CalendarItemFromJson(json['calendarItem'] ?? json);

  /// Local start: a date-only value is a local day, not UTC midnight, so it is
  /// not parsed with the UTC DateTimeConverter.
  DateTime? get startLocal => _parse(start);

  DateTime? get endLocal => _parse(end);

  static DateTime? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return value.length == 10 ? parsed : parsed.toLocal();
  }

  @override
  List<Object?> get props => [source, itemId];

  @override
  String toString() => 'CalendarItem $source $title [$itemId] $start';
}

@freezed
abstract class CalendarItems with _$CalendarItems {
  factory CalendarItems({
    @Default(false) bool calendarConnected,
    @Default([]) List<CalendarItem> calendarItems,
  }) = _CalendarItems;
  CalendarItems._();

  factory CalendarItems.fromJson(Map<String, dynamic> json) =>
      _$CalendarItemsFromJson(json);
}
