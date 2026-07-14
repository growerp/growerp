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

part 'outreach_dashboard_model.freezed.dart';
part 'outreach_dashboard_model.g.dart';

@freezed
abstract class OutreachStatusSummaryItem with _$OutreachStatusSummaryItem {
  OutreachStatusSummaryItem._();
  factory OutreachStatusSummaryItem({
    @Default("") String status,
    @Default(0) int count,
  }) = _OutreachStatusSummaryItem;

  factory OutreachStatusSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$OutreachStatusSummaryItemFromJson(json);
}

@freezed
abstract class OutreachDashboard with _$OutreachDashboard {
  OutreachDashboard._();
  factory OutreachDashboard({
    @Default([]) List<OutreachStatusSummaryItem> statusSummary,
    @Default(0) int totalCampaigns,
    @Default(0) int activeCampaigns,
    @Default(0) int messagesSent,
    @Default(0) int responsesReceived,
  }) = _OutreachDashboard;

  factory OutreachDashboard.fromJson(Map<String, dynamic> json) =>
      _$OutreachDashboardFromJson(json);
}
