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

part 'agent_task_model.g.dart';

/// Status of an agent task
enum TaskStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('QUEUED')
  queued,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
  @JsonValue('AWAITING_APPROVAL')
  awaitingApproval,
}

/// Represents a task to be executed by an agent
@JsonSerializable()
class AgentTask {
  final String? taskId;
  final String? pseudoId;
  final String? instanceId;
  final String? taskType;
  final int? priority;
  final TaskStatus? status;
  final Map<String, dynamic>? inputData;
  final Map<String, dynamic>? outputData;
  final String? errorMessage;
  final int? retryCount;
  final int? maxRetries;
  final DateTime? scheduledDate;
  final DateTime? startedDate;
  final DateTime? completedDate;
  final DateTime? createdDate;

  // For display purposes
  final String? agentName;
  final String? instanceName;

  const AgentTask({
    this.taskId,
    this.pseudoId,
    this.instanceId,
    this.taskType,
    this.priority,
    this.status,
    this.inputData,
    this.outputData,
    this.errorMessage,
    this.retryCount,
    this.maxRetries,
    this.scheduledDate,
    this.startedDate,
    this.completedDate,
    this.createdDate,
    this.agentName,
    this.instanceName,
  });

  factory AgentTask.fromJson(Map<String, dynamic> json) =>
      _$AgentTaskFromJson(json);
  Map<String, dynamic> toJson() => _$AgentTaskToJson(this);

  AgentTask copyWith({
    String? taskId,
    String? pseudoId,
    String? instanceId,
    String? taskType,
    int? priority,
    TaskStatus? status,
    Map<String, dynamic>? inputData,
    Map<String, dynamic>? outputData,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
    DateTime? scheduledDate,
    DateTime? startedDate,
    DateTime? completedDate,
    DateTime? createdDate,
    String? agentName,
    String? instanceName,
  }) {
    return AgentTask(
      taskId: taskId ?? this.taskId,
      pseudoId: pseudoId ?? this.pseudoId,
      instanceId: instanceId ?? this.instanceId,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      inputData: inputData ?? this.inputData,
      outputData: outputData ?? this.outputData,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedDate: startedDate ?? this.startedDate,
      completedDate: completedDate ?? this.completedDate,
      createdDate: createdDate ?? this.createdDate,
      agentName: agentName ?? this.agentName,
      instanceName: instanceName ?? this.instanceName,
    );
  }

  /// Get duration of task execution
  Duration? get executionDuration {
    if (startedDate == null) return null;
    final endDate = completedDate ?? DateTime.now();
    return endDate.difference(startedDate!);
  }

  /// Check if task can be retried
  bool get canRetry =>
      status == TaskStatus.failed && (retryCount ?? 0) < (maxRetries ?? 3);

  @override
  String toString() => 'AgentTask[$taskId: $taskType ($status)]';
}
