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

part 'adk_agent_config_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkAgentConfig {
  final String? adkAgentConfigId;
  final String? agentName;
  final String? modelName;
  final String? instruction;
  final String? description;
  @JsonKey(defaultValue: true)
  final bool enabled;
  final String? scheduleExpression;
  @JsonKey(defaultValue: false)
  final bool scheduleEnabled;
  final String? schedulePrompt;
  final String? scheduleChatRoomId;

  /// Write-only: sent on create/update, never returned by GET.
  @JsonKey(includeFromJson: false)
  final String? apiKey;

  const AdkAgentConfig({
    this.adkAgentConfigId,
    this.agentName,
    this.modelName,
    this.instruction,
    this.description,
    this.enabled = true,
    this.scheduleExpression,
    this.scheduleEnabled = false,
    this.schedulePrompt,
    this.scheduleChatRoomId,
    this.apiKey,
  });

  factory AdkAgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AdkAgentConfigToJson(this);

  AdkAgentConfig copyWith({
    String? adkAgentConfigId,
    String? agentName,
    String? modelName,
    String? instruction,
    String? description,
    bool? enabled,
    String? scheduleExpression,
    bool? scheduleEnabled,
    String? schedulePrompt,
    String? scheduleChatRoomId,
    String? apiKey,
  }) =>
      AdkAgentConfig(
        adkAgentConfigId: adkAgentConfigId ?? this.adkAgentConfigId,
        agentName: agentName ?? this.agentName,
        modelName: modelName ?? this.modelName,
        instruction: instruction ?? this.instruction,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
        scheduleExpression: scheduleExpression ?? this.scheduleExpression,
        scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
        schedulePrompt: schedulePrompt ?? this.schedulePrompt,
        scheduleChatRoomId: scheduleChatRoomId ?? this.scheduleChatRoomId,
        apiKey: apiKey ?? this.apiKey,
      );

  @override
  String toString() => 'AdkAgentConfig[$adkAgentConfigId: $agentName]';
}

@JsonSerializable()
class AdkAgentConfigs {
  final List<AdkAgentConfig> adkAgentConfigs;

  const AdkAgentConfigs({required this.adkAgentConfigs});

  factory AdkAgentConfigs.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentConfigsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentConfigsToJson(this);
}
