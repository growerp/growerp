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
import 'package:growerp_models/growerp_models.dart';

part 'marketing_dashboard_model.freezed.dart';
part 'marketing_dashboard_model.g.dart';

@freezed
abstract class CampaignSummaryItem with _$CampaignSummaryItem {
  CampaignSummaryItem._();
  factory CampaignSummaryItem({
    @Default("") String marketingCampaignId,
    @Default("") String campaignName,
    @Default("") String statusId,
    @Default(0) int messagesSent,
    @Default(0) int responsesReceived,
    @Default(0) int leadsGenerated,
  }) = _CampaignSummaryItem;

  factory CampaignSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$CampaignSummaryItemFromJson(json);
}

@freezed
abstract class MarketingDashboard with _$MarketingDashboard {
  MarketingDashboard._();
  factory MarketingDashboard({
    @Default([]) List<OpportunitySummaryItem> stageSummary,
    @Default([]) List<CampaignSummaryItem> campaigns,
    @Default(0) int totalLeads,
    @Default(0) int assessmentCompletions,
    @Default(0) int activeEnrollments,
    @Default(0) int completedEnrollments,
  }) = _MarketingDashboard;

  factory MarketingDashboard.fromJson(Map<String, dynamic> json) =>
      _$MarketingDashboardFromJson(json);
}
