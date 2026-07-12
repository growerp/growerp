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
