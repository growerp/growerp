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

part 'adk_action_model.g.dart';

/// One audited agent tool/service action (read, write, blocked, pending, …).
/// Tenant-scoped server-side: the REST endpoint only returns the caller's company.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkActionLog {
  final String? adkActionLogId;
  final String? configId;
  final String? ownerPartyId;
  final String? tenantName;
  final String? agentPartyId;
  final String? toolName;
  final String? serviceName;
  final String? argsJson;

  /// read | write
  final String? verbClass;

  /// allowed | blocked | pending | approved | rejected
  final String? decision;
  final String? reason;
  final String? resultSummary;
  final int? tokensIn;
  final int? tokensOut;
  final int? tokensTotal;
  @NullableTimestampConverter()
  final DateTime? actionTime;

  const AdkActionLog({
    this.adkActionLogId,
    this.configId,
    this.ownerPartyId,
    this.tenantName,
    this.agentPartyId,
    this.toolName,
    this.serviceName,
    this.argsJson,
    this.verbClass,
    this.decision,
    this.reason,
    this.resultSummary,
    this.tokensIn,
    this.tokensOut,
    this.tokensTotal,
    this.actionTime,
  });

  factory AdkActionLog.fromJson(Map<String, dynamic> json) =>
      _$AdkActionLogFromJson(json);
  Map<String, dynamic> toJson() => _$AdkActionLogToJson(this);

  @override
  String toString() =>
      'AdkActionLog[$adkActionLogId: $serviceName $verbClass/$decision]';
}

@JsonSerializable()
class AdkActionLogs {
  final List<AdkActionLog> adkActions;

  const AdkActionLogs({this.adkActions = const []});

  factory AdkActionLogs.fromJson(Map<String, dynamic> json) =>
      _$AdkActionLogsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkActionLogsToJson(this);
}
