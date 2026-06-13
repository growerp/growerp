/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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
