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
