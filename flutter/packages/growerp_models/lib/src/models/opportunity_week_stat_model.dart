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

import 'opportunity_summary_model.dart';

part 'opportunity_week_stat_model.freezed.dart';
part 'opportunity_week_stat_model.g.dart';

/// One weekly snapshot of the opportunity pipeline: the totals of the week with
/// the per stage detail. The backend sends the newest week first.
/// [weekStartDate] is a plain date (the monday of the week), not a timestamp, so
/// it is parsed as is without the UTC conversion of the DateTimeConverter.
@freezed
abstract class OpportunityWeekStatItem with _$OpportunityWeekStatItem {
  OpportunityWeekStatItem._();
  factory OpportunityWeekStatItem({
    DateTime? weekStartDate,
    @Default(0) int opportunityCount,
    Decimal? totalAmount,
    Decimal? weightedAmount,
    @Default([]) List<OpportunitySummaryItem> stages,
  }) = _OpportunityWeekStatItem;

  factory OpportunityWeekStatItem.fromJson(Map<String, dynamic> json) =>
      _$OpportunityWeekStatItemFromJson(json['week'] ?? json);
}

@freezed
abstract class OpportunityWeekStats with _$OpportunityWeekStats {
  OpportunityWeekStats._();
  factory OpportunityWeekStats({
    @Default([]) List<OpportunityWeekStatItem> weekSummary,
  }) = _OpportunityWeekStats;

  factory OpportunityWeekStats.fromJson(Map<String, dynamic> json) =>
      _$OpportunityWeekStatsFromJson(json);
}
