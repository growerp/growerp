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

/// Represents one ADK agent configuration stored in AdkAgentConfig entity.
class AdkAgentConfig {
  final String? adkAgentConfigId;
  final String? agentName;
  final String? modelName;
  final String? instruction;
  final String? description;
  final bool enabled;
  final String? scheduleExpression;
  final bool scheduleEnabled;
  final String? schedulePrompt;
  final String? scheduleChatRoomId;

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
  });

  factory AdkAgentConfig.fromJson(Map<String, dynamic> json) => AdkAgentConfig(
        adkAgentConfigId: json['adkAgentConfigId'] as String?,
        agentName: json['agentName'] as String?,
        modelName: json['modelName'] as String?,
        instruction: json['instruction'] as String?,
        description: json['description'] as String?,
        enabled: json['enabled'] == 'Y',
        scheduleExpression: json['scheduleExpression'] as String?,
        scheduleEnabled: json['scheduleEnabled'] == 'Y',
        schedulePrompt: json['schedulePrompt'] as String?,
        scheduleChatRoomId: json['scheduleChatRoomId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (adkAgentConfigId != null) 'adkAgentConfigId': adkAgentConfigId,
        if (agentName != null) 'agentName': agentName,
        if (modelName != null) 'modelName': modelName,
        if (instruction != null) 'instruction': instruction,
        if (description != null) 'description': description,
        'enabled': enabled ? 'Y' : 'N',
        if (scheduleExpression != null)
          'scheduleExpression': scheduleExpression,
        'scheduleEnabled': scheduleEnabled ? 'Y' : 'N',
        if (schedulePrompt != null) 'schedulePrompt': schedulePrompt,
        if (scheduleChatRoomId != null)
          'scheduleChatRoomId': scheduleChatRoomId,
      };

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
      );
}
