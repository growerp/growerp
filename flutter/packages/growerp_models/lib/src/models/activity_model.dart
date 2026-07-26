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
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

@freezed
abstract class Activity extends Equatable with _$Activity {
  const Activity._();
  const factory Activity({
    @Default("") String activityId,
    @Default("") String pseudoId,
    ActivityType? activityType, // todo, event
    UserGroup? userGroup,
    @Default("") String parentActivityId,
    ActivityStatus? statusId,
    @Default("") String activityName,
    @Default("") String description,
    Opportunity? opportunity,
    User? originator,
    User? assignee,
    User? thirdParty,
    Decimal? rate,
    DateTime? actualStartDate,
    DateTime? actualEndDate,
    DateTime? estimatedStartDate,
    DateTime? estimatedEndDate,
    Decimal? unInvoicedHours,
    @Default([]) List<TimeEntry> timeEntries,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json['activity'] ?? json);

  @override
  List<Object?> get props => [activityId];

  @override
  String toString() =>
      'Activity $activityName [$activityId] #timeEntries: ${timeEntries.length}';
}
