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
import 'assessment_model.dart' show NullableTimestampConverter;

part 'adk_approval_model.g.dart';

/// A pending (or decided) human-in-the-loop approval for an agent write action.
/// Tenant-scoped server-side: a company only sees and decides its own approvals.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkApproval {
  final String? adkApprovalId;
  final String? adkActionLogId;
  final String? configId;
  final String? serviceName;
  final String? argsJson;

  /// pending | approved | rejected | expired
  final String? status;
  final String? requestedByUserId;
  final String? decidedByUserId;
  @NullableTimestampConverter()
  final DateTime? requestTime;
  @NullableTimestampConverter()
  final DateTime? decisionTime;

  const AdkApproval({
    this.adkApprovalId,
    this.adkActionLogId,
    this.configId,
    this.serviceName,
    this.argsJson,
    this.status,
    this.requestedByUserId,
    this.decidedByUserId,
    this.requestTime,
    this.decisionTime,
  });

  factory AdkApproval.fromJson(Map<String, dynamic> json) =>
      _$AdkApprovalFromJson(json);
  Map<String, dynamic> toJson() => _$AdkApprovalToJson(this);

  @override
  String toString() => 'AdkApproval[$adkApprovalId: $serviceName ($status)]';
}

@JsonSerializable()
class AdkApprovals {
  final List<AdkApproval> adkApprovals;

  const AdkApprovals({this.adkApprovals = const []});

  factory AdkApprovals.fromJson(Map<String, dynamic> json) =>
      _$AdkApprovalsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkApprovalsToJson(this);
}
