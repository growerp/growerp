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
