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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketing_dashboard_model.freezed.dart';
part 'marketing_dashboard_model.g.dart';

@freezed
abstract class ContentStatusSummaryItem with _$ContentStatusSummaryItem {
  ContentStatusSummaryItem._();
  factory ContentStatusSummaryItem({
    @Default("") String status,
    @Default(0) int count,
  }) = _ContentStatusSummaryItem;

  factory ContentStatusSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$ContentStatusSummaryItemFromJson(json);
}

@freezed
abstract class MarketingDashboard with _$MarketingDashboard {
  MarketingDashboard._();
  factory MarketingDashboard({
    @Default([]) List<ContentStatusSummaryItem> postSummary,
    @Default(0) int totalPosts,
    @Default(0) int contentToApprove,
    @Default(0) int activePlans,
    @Default(0) int newEngagements,
  }) = _MarketingDashboard;

  factory MarketingDashboard.fromJson(Map<String, dynamic> json) =>
      _$MarketingDashboardFromJson(json);
}
