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

part 'adk_agent_config_model.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkAgentConfig {
  final String? adkAgentConfigId;
  final String? agentName;
  final String? modelName;
  final String? llmProvider;
  final String? instruction;
  final String? description;
  @JsonKey(defaultValue: true)
  final bool enabled;
  final String? scheduleExpression;
  @JsonKey(defaultValue: false)
  final bool scheduleEnabled;
  final String? schedulePrompt;
  final String? scheduleChatRoomId;

  // Trust foundation: per-agent tool/service scoping + write governance.
  /// readOnly | scoped | full
  final String? toolMode;

  /// CSV/JSON of service-name globs allowed when toolMode == scoped
  final String? serviceAllowlist;

  /// block | approve | allow
  final String? writePolicy;
  final String? approvalChatRoomId;
  final String? agentPartyId;

  /// Y → this agent answers the tenant's public website chat.
  @JsonKey(defaultValue: false)
  final bool websiteChat;

  // Multi-agent orchestration (Phase 4).
  /// specialist | coordinator | workflow
  final String? agentRole;

  /// router | sequential | parallel | loop  (coordinator/workflow only)
  final String? orchestrationType;
  final int? loopMaxIterations;

  /// Write-only: sent on create/update, never returned by GET.
  @JsonKey(includeFromJson: false)
  final String? apiKey;

  const AdkAgentConfig({
    this.adkAgentConfigId,
    this.agentName,
    this.modelName,
    this.llmProvider,
    this.instruction,
    this.description,
    this.enabled = true,
    this.scheduleExpression,
    this.scheduleEnabled = false,
    this.schedulePrompt,
    this.scheduleChatRoomId,
    this.toolMode,
    this.serviceAllowlist,
    this.writePolicy,
    this.approvalChatRoomId,
    this.agentPartyId,
    this.websiteChat = false,
    this.agentRole,
    this.orchestrationType,
    this.loopMaxIterations,
    this.apiKey,
  });

  factory AdkAgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AdkAgentConfigToJson(this);

  AdkAgentConfig copyWith({
    String? adkAgentConfigId,
    String? agentName,
    String? modelName,
    String? llmProvider,
    String? instruction,
    String? description,
    bool? enabled,
    String? scheduleExpression,
    bool? scheduleEnabled,
    String? schedulePrompt,
    String? scheduleChatRoomId,
    String? toolMode,
    String? serviceAllowlist,
    String? writePolicy,
    String? approvalChatRoomId,
    String? agentPartyId,
    bool? websiteChat,
    String? agentRole,
    String? orchestrationType,
    int? loopMaxIterations,
    String? apiKey,
  }) =>
      AdkAgentConfig(
        adkAgentConfigId: adkAgentConfigId ?? this.adkAgentConfigId,
        agentName: agentName ?? this.agentName,
        modelName: modelName ?? this.modelName,
        llmProvider: llmProvider ?? this.llmProvider,
        instruction: instruction ?? this.instruction,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
        scheduleExpression: scheduleExpression ?? this.scheduleExpression,
        scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
        schedulePrompt: schedulePrompt ?? this.schedulePrompt,
        scheduleChatRoomId: scheduleChatRoomId ?? this.scheduleChatRoomId,
        toolMode: toolMode ?? this.toolMode,
        serviceAllowlist: serviceAllowlist ?? this.serviceAllowlist,
        writePolicy: writePolicy ?? this.writePolicy,
        approvalChatRoomId: approvalChatRoomId ?? this.approvalChatRoomId,
        agentPartyId: agentPartyId ?? this.agentPartyId,
        websiteChat: websiteChat ?? this.websiteChat,
        agentRole: agentRole ?? this.agentRole,
        orchestrationType: orchestrationType ?? this.orchestrationType,
        loopMaxIterations: loopMaxIterations ?? this.loopMaxIterations,
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
