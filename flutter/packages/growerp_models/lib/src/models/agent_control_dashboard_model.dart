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

part 'agent_control_dashboard_model.freezed.dart';
part 'agent_control_dashboard_model.g.dart';

@freezed
abstract class AgentControlStageSummaryItem
    with _$AgentControlStageSummaryItem {
  AgentControlStageSummaryItem._();
  factory AgentControlStageSummaryItem({
    @Default("") String stageId,
    @Default("") String stageName,
    @Default(0) int count,
  }) = _AgentControlStageSummaryItem;

  factory AgentControlStageSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$AgentControlStageSummaryItemFromJson(json);
}

@freezed
abstract class AgentControlDashboard with _$AgentControlDashboard {
  AgentControlDashboard._();
  factory AgentControlDashboard({
    @Default([]) List<AgentControlStageSummaryItem> stageSummary,
    @Default(0) int totalAgents,
    @Default(0) int enabledAgents,
    @Default(0) int scheduledAgents,
    @Default(0) int mcpServers,
  }) = _AgentControlDashboard;

  factory AgentControlDashboard.fromJson(Map<String, dynamic> json) =>
      _$AgentControlDashboardFromJson(json);
}
