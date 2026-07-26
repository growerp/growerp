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
