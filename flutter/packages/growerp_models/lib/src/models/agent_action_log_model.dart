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
