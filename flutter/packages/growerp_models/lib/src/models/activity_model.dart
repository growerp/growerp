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
