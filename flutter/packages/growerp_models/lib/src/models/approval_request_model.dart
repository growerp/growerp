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

part 'approval_request_model.g.dart';

/// Status of an approval request
enum ApprovalStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('EXPIRED')
  expired,
}

/// Represents a human approval request from an agent
@JsonSerializable()
class ApprovalRequest {
  final String? requestId;
  final String? instanceId;
  final String? taskId;
  final String? requestType;
  final String? description;
  final Map<String, dynamic>? context;
  final String? recommendedAction;
  final ApprovalStatus? status;
  final String? approverPartyId;
  final String? approverComment;
  final DateTime? expiresDate;
  final DateTime? createdDate;
  final DateTime? resolvedDate;

  // From join with AgentInstance
  final String? agentName;
  final String? agentId;
  final String? ownerPartyId;

  const ApprovalRequest({
    this.requestId,
    this.instanceId,
    this.taskId,
    this.requestType,
    this.description,
    this.context,
    this.recommendedAction,
    this.status,
    this.approverPartyId,
    this.approverComment,
    this.expiresDate,
    this.createdDate,
    this.resolvedDate,
    this.agentName,
    this.agentId,
    this.ownerPartyId,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApprovalRequestToJson(this);

  ApprovalRequest copyWith({
    String? requestId,
    String? instanceId,
    String? taskId,
    String? requestType,
    String? description,
    Map<String, dynamic>? context,
    String? recommendedAction,
    ApprovalStatus? status,
    String? approverPartyId,
    String? approverComment,
    DateTime? expiresDate,
    DateTime? createdDate,
    DateTime? resolvedDate,
    String? agentName,
    String? agentId,
    String? ownerPartyId,
  }) {
    return ApprovalRequest(
      requestId: requestId ?? this.requestId,
      instanceId: instanceId ?? this.instanceId,
      taskId: taskId ?? this.taskId,
      requestType: requestType ?? this.requestType,
      description: description ?? this.description,
      context: context ?? this.context,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      status: status ?? this.status,
      approverPartyId: approverPartyId ?? this.approverPartyId,
      approverComment: approverComment ?? this.approverComment,
      expiresDate: expiresDate ?? this.expiresDate,
      createdDate: createdDate ?? this.createdDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      agentName: agentName ?? this.agentName,
      agentId: agentId ?? this.agentId,
      ownerPartyId: ownerPartyId ?? this.ownerPartyId,
    );
  }

  /// Check if the approval request is expired
  bool get isExpired {
    if (expiresDate == null) return false;
    return DateTime.now().isAfter(expiresDate!);
  }

  /// Get time remaining until expiration
  Duration? get timeRemaining {
    if (expiresDate == null) return null;
    final remaining = expiresDate!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if request is still actionable
  bool get isActionable => status == ApprovalStatus.pending && !isExpired;

  @override
  String toString() => 'ApprovalRequest[$requestId: $requestType ($status)]';
}
