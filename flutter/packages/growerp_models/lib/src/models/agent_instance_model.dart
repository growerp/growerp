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

part 'agent_instance_model.g.dart';

/// Status of an agent instance
enum AgentStatus {
  @JsonValue('INACTIVE')
  inactive,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('ERROR')
  error,
}

/// Type of business agent
enum AgentType {
  @JsonValue('AGENT_MARKETING')
  marketing,
  @JsonValue('AGENT_SALES')
  sales,
  @JsonValue('AGENT_OPERATIONS')
  operations,
  @JsonValue('AGENT_FINANCE')
  finance,
  @JsonValue('AGENT_SUPPORT')
  support,
}

/// Statistics for an agent instance
@JsonSerializable()
class AgentStats {
  final int? totalTasks;
  final int? completedTasks;
  final int? failedTasks;
  final int? pendingTasks;
  final int? pendingApprovals;
  final int? todayTasks;
  final double? successRate;
  final DateTime? lastActivity;

  const AgentStats({
    this.totalTasks,
    this.completedTasks,
    this.failedTasks,
    this.pendingTasks,
    this.pendingApprovals,
    this.todayTasks,
    this.successRate,
    this.lastActivity,
  });

  factory AgentStats.fromJson(Map<String, dynamic> json) =>
      _$AgentStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AgentStatsToJson(this);
}

/// Represents a running instance of an agent for a specific company
@JsonSerializable()
class AgentInstance {
  final String? instanceId;
  final String? pseudoId;
  final String? agentId;
  final String? ownerPartyId;
  final String? name;
  final AgentStatus? status;
  final Map<String, dynamic>? configuration;
  final DateTime? lastExecutionDate;
  final DateTime? nextScheduledDate;
  final String? errorMessage;
  final int? errorCount;
  final DateTime? createdDate;
  final String? createdByUserLogin;
  final DateTime? lastModifiedDate;

  // From join with BusinessAgent
  final String? agentName;
  final AgentType? agentTypeEnumId;
  final String? agentDescription;
  final List<String>? capabilities;

  // Computed statistics
  final AgentStats? stats;

  const AgentInstance({
    this.instanceId,
    this.pseudoId,
    this.agentId,
    this.ownerPartyId,
    this.name,
    this.status,
    this.configuration,
    this.lastExecutionDate,
    this.nextScheduledDate,
    this.errorMessage,
    this.errorCount,
    this.createdDate,
    this.createdByUserLogin,
    this.lastModifiedDate,
    this.agentName,
    this.agentTypeEnumId,
    this.agentDescription,
    this.capabilities,
    this.stats,
  });

  factory AgentInstance.fromJson(Map<String, dynamic> json) =>
      _$AgentInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$AgentInstanceToJson(this);

  AgentInstance copyWith({
    String? instanceId,
    String? pseudoId,
    String? agentId,
    String? ownerPartyId,
    String? name,
    AgentStatus? status,
    Map<String, dynamic>? configuration,
    DateTime? lastExecutionDate,
    DateTime? nextScheduledDate,
    String? errorMessage,
    int? errorCount,
    DateTime? createdDate,
    String? createdByUserLogin,
    DateTime? lastModifiedDate,
    String? agentName,
    AgentType? agentTypeEnumId,
    String? agentDescription,
    List<String>? capabilities,
    AgentStats? stats,
  }) {
    return AgentInstance(
      instanceId: instanceId ?? this.instanceId,
      pseudoId: pseudoId ?? this.pseudoId,
      agentId: agentId ?? this.agentId,
      ownerPartyId: ownerPartyId ?? this.ownerPartyId,
      name: name ?? this.name,
      status: status ?? this.status,
      configuration: configuration ?? this.configuration,
      lastExecutionDate: lastExecutionDate ?? this.lastExecutionDate,
      nextScheduledDate: nextScheduledDate ?? this.nextScheduledDate,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCount: errorCount ?? this.errorCount,
      createdDate: createdDate ?? this.createdDate,
      createdByUserLogin: createdByUserLogin ?? this.createdByUserLogin,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      agentName: agentName ?? this.agentName,
      agentTypeEnumId: agentTypeEnumId ?? this.agentTypeEnumId,
      agentDescription: agentDescription ?? this.agentDescription,
      capabilities: capabilities ?? this.capabilities,
      stats: stats ?? this.stats,
    );
  }

  @override
  String toString() => 'AgentInstance[$instanceId: $name ($status)]';
}
