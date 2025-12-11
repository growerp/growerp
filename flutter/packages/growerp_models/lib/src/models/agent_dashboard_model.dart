/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
