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

import 'package:json_annotation/json_annotation.dart';
import 'agent_instance_model.dart';
import 'agent_action_log_model.dart';
import 'approval_request_model.dart';

part 'agent_dashboard_model.g.dart';

/// Dashboard statistics for the agent manager
@JsonSerializable()
class AgentDashboardStats {
  final int? activeAgents;
  final int? totalAgents;
  final int? tasksToday;
  final int? tasksCompleted;
  final int? tasksFailed;
  final int? pendingApprovals;
  final double? successRate;
  final int? messagesProcessed;
  final int? leadsGenerated;

  const AgentDashboardStats({
    this.activeAgents,
    this.totalAgents,
    this.tasksToday,
    this.tasksCompleted,
    this.tasksFailed,
    this.pendingApprovals,
    this.successRate,
    this.messagesProcessed,
    this.leadsGenerated,
  });

  factory AgentDashboardStats.fromJson(Map<String, dynamic> json) =>
      _$AgentDashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AgentDashboardStatsToJson(this);
}

/// Complete dashboard data for the agent manager UI
@JsonSerializable()
class AgentDashboard {
  final List<AgentInstance>? agents;
  final List<ApprovalRequest>? pendingApprovals;
  final List<AgentActionLog>? recentActivity;
  final AgentDashboardStats? statistics;

  const AgentDashboard({
    this.agents,
    this.pendingApprovals,
    this.recentActivity,
    this.statistics,
  });

  factory AgentDashboard.fromJson(Map<String, dynamic> json) =>
      _$AgentDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$AgentDashboardToJson(this);

  /// Get only active agents
  List<AgentInstance> get activeAgents =>
      agents?.where((a) => a.status == AgentStatus.active).toList() ?? [];

  /// Get agents with errors
  List<AgentInstance> get errorAgents =>
      agents?.where((a) => a.status == AgentStatus.error).toList() ?? [];

  /// Check if there are urgent approvals (expiring soon)
  List<ApprovalRequest> get urgentApprovals {
    final now = DateTime.now();
    return pendingApprovals?.where((a) {
          if (a.expiresDate == null) return false;
          final hoursRemaining = a.expiresDate!.difference(now).inHours;
          return hoursRemaining < 2 && hoursRemaining >= 0;
        }).toList() ??
        [];
  }
}
