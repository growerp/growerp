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
