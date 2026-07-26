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

part 'agent_action_log_model.g.dart';

/// Result of an agent action
enum ActionResult {
  @JsonValue('SUCCESS')
  success,
  @JsonValue('FAILURE')
  failure,
  @JsonValue('PENDING_APPROVAL')
  pendingApproval,
}

/// Represents a logged agent action for audit purposes
@JsonSerializable()
class AgentActionLog {
  final String? logId;
  final String? instanceId;
  final String? taskId;
  final String? actionType;
  final Map<String, dynamic>? actionDetails;
  final String? affectedEntityType;
  final String? affectedEntityId;
  final ActionResult? result;
  final String? errorMessage;
  final int? executionTimeMs;
  final DateTime? timestamp;

  // For display purposes
  final String? agentName;
  final String? instanceName;

  const AgentActionLog({
    this.logId,
    this.instanceId,
    this.taskId,
    this.actionType,
    this.actionDetails,
    this.affectedEntityType,
    this.affectedEntityId,
    this.result,
    this.errorMessage,
    this.executionTimeMs,
    this.timestamp,
    this.agentName,
    this.instanceName,
  });

  factory AgentActionLog.fromJson(Map<String, dynamic> json) =>
      _$AgentActionLogFromJson(json);
  Map<String, dynamic> toJson() => _$AgentActionLogToJson(this);

  /// Get a human-readable description of the action
  String get actionDescription {
    final action = actionType ?? 'Unknown action';
    final entity = affectedEntityType != null ? ' on $affectedEntityType' : '';
    final entityId = affectedEntityId != null ? ' ($affectedEntityId)' : '';
    return '$action$entity$entityId';
  }

  /// Get execution time as Duration
  Duration? get executionDuration {
    if (executionTimeMs == null) return null;
    return Duration(milliseconds: executionTimeMs!);
  }

  @override
  String toString() => 'AgentActionLog[$logId: $actionType ($result)]';
}
