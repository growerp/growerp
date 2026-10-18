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
  /// Only ever populated cross-tenant, by the support app's
  /// get#NominatedAgents (catalog promotion queue) — a tenant's own
  /// get#AdkAgentConfig never sends its own ownerPartyId back.
  final String? ownerPartyId;
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

  /// Y → this agent gets the Google Search tool (Gemini only).
  @JsonKey(defaultValue: false)
  final bool webSearch;

  // Multi-agent orchestration (Phase 4).
  /// specialist | coordinator | workflow
  final String? agentRole;

  /// router | sequential | parallel | loop  (coordinator/workflow only)
  final String? orchestrationType;
  final int? loopMaxIterations;

  /// LLM calls allowed per run; null = backend default (10).
  final int? maxLlmCalls;

  /// Free-form label; agents sharing (ownerPartyId, teamName) are grouped as one team in
  /// the Agent Control Center UI and can be downloaded/uploaded together.
  final String? teamName;

  /// Y → the owning tenant asked for this agent to be reviewed for the shared
  /// catalog (support app's AdkCatalogPromotionView). Never makes it visible
  /// or usable by another tenant on its own.
  @JsonKey(defaultValue: false)
  final bool catalogNominated;

  /// Shared catalog ("_NA_") agents only: false → draft, hidden from tenants'
  /// function catalog and the public website list.
  @JsonKey(defaultValue: true)
  final bool catalogPublished;

  /// Shared catalog agents only: grouping label (Marketing, Operations, ...).
  final String? catalogCategory;

  /// Task loop: the agent's schedule works its task inbox (new messages in
  /// [loopChatRoomId] + todo activities assigned to the agent) instead of
  /// running [schedulePrompt]. Reports go to [loopReportEmail], else to the
  /// requester.
  @JsonKey(defaultValue: false)
  final bool loopEnabled;
  final String? loopChatRoomId;
  final String? loopReportEmail;

  /// Write-only: sent on create/update, never returned by GET.
  @JsonKey(includeFromJson: false)
  final String? apiKey;

  const AdkAgentConfig({
    this.adkAgentConfigId,
    this.ownerPartyId,
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
    this.webSearch = false,
    this.agentRole,
    this.orchestrationType,
    this.loopMaxIterations,
    this.maxLlmCalls,
    this.teamName,
    this.catalogNominated = false,
    this.catalogPublished = true,
    this.catalogCategory,
    this.loopEnabled = false,
    this.loopChatRoomId,
    this.loopReportEmail,
    this.apiKey,
  });

  factory AdkAgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AdkAgentConfigToJson(this);

  AdkAgentConfig copyWith({
    String? adkAgentConfigId,
    String? ownerPartyId,
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
    bool? webSearch,
    String? agentRole,
    String? orchestrationType,
    int? loopMaxIterations,
    int? maxLlmCalls,
    String? teamName,
    bool? catalogNominated,
    bool? catalogPublished,
    String? catalogCategory,
    bool? loopEnabled,
    String? loopChatRoomId,
    String? loopReportEmail,
    String? apiKey,
  }) =>
      AdkAgentConfig(
        adkAgentConfigId: adkAgentConfigId ?? this.adkAgentConfigId,
        ownerPartyId: ownerPartyId ?? this.ownerPartyId,
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
        webSearch: webSearch ?? this.webSearch,
        agentRole: agentRole ?? this.agentRole,
        orchestrationType: orchestrationType ?? this.orchestrationType,
        loopMaxIterations: loopMaxIterations ?? this.loopMaxIterations,
        maxLlmCalls: maxLlmCalls ?? this.maxLlmCalls,
        teamName: teamName ?? this.teamName,
        catalogNominated: catalogNominated ?? this.catalogNominated,
        catalogPublished: catalogPublished ?? this.catalogPublished,
        catalogCategory: catalogCategory ?? this.catalogCategory,
        loopEnabled: loopEnabled ?? this.loopEnabled,
        loopChatRoomId: loopChatRoomId ?? this.loopChatRoomId,
        loopReportEmail: loopReportEmail ?? this.loopReportEmail,
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

/// A downloadable team file: `jsonText` is the exact bytes to save/read back.
@JsonSerializable()
class AdkAgentTeamExport {
  final String? fileName;
  final String? jsonText;

  const AdkAgentTeamExport({this.fileName, this.jsonText});

  factory AdkAgentTeamExport.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTeamExportFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentTeamExportToJson(this);
}

@JsonSerializable()
class AdkAgentTeamImportResult {
  final String? importedTeamName;
  final int? importedAgentCount;

  const AdkAgentTeamImportResult(
      {this.importedTeamName, this.importedAgentCount});

  factory AdkAgentTeamImportResult.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTeamImportResultFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentTeamImportResultToJson(this);
}

/// One rule-check finding on an agent configuration (no AI call involved).
@JsonSerializable()
class AdkAgentCheckIssue {
  /// error | warning
  final String level;
  final String? field;
  final String message;

  const AdkAgentCheckIssue(
      {required this.level, this.field, required this.message});

  bool get isError => level == 'error';

  factory AdkAgentCheckIssue.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentCheckIssueFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentCheckIssueToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AdkAgentCheckResult {
  @JsonKey(defaultValue: [])
  final List<AdkAgentCheckIssue> issues;

  const AdkAgentCheckResult({required this.issues});

  factory AdkAgentCheckResult.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentCheckResultFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentCheckResultToJson(this);
}

/// Answer to starting a test run: no [testRunId] when a check error stopped it.
@JsonSerializable(explicitToJson: true)
class AdkAgentTestStart {
  final String? testRunId;
  @JsonKey(defaultValue: [])
  final List<AdkAgentCheckIssue> issues;

  const AdkAgentTestStart({this.testRunId, required this.issues});

  factory AdkAgentTestStart.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTestStartFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentTestStartToJson(this);
}

/// One tool call made during a test run.
@JsonSerializable()
class AdkAgentToolCall {
  final String? tool;
  final String? service;
  final String? args;
  final String? result;

  /// ok | simulated | approval | blocked; null while the call is running
  final String? decision;

  const AdkAgentToolCall(
      {this.tool, this.service, this.args, this.result, this.decision});

  factory AdkAgentToolCall.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentToolCallFromJson(json);
  Map<String, dynamic> toJson() => _$AdkAgentToolCallToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AdkAgentTestRun {
  final String? testRunId;

  /// running | done | failed
  final String? status;
  @JsonKey(defaultValue: true)
  final bool dryRun;
  final String? response;
  final String? error;
  final String? hint;
  @JsonKey(defaultValue: [])
  final List<AdkAgentToolCall> toolCalls;
  final int? llmCalls;
  final int? maxLlmCalls;
  final int? tokensTotal;
  final int? durationMs;

  const AdkAgentTestRun({
    this.testRunId,
    this.status,
    this.dryRun = true,
    this.response,
    this.error,
    this.hint,
    this.toolCalls = const [],
    this.llmCalls,
    this.maxLlmCalls,
    this.tokensTotal,
    this.durationMs,
  });

  bool get isRunning => status == 'running';

  factory AdkAgentTestRun.fromJson(Map<String, dynamic> json) =>
      _$AdkAgentTestRunFromJson(json['testRun'] ?? json);
  Map<String, dynamic> toJson() => _$AdkAgentTestRunToJson(this);
}

/// The server's time zone and the next runs of a cron expression
/// (AdkSchedulerServices.get#SchedulePreview). Agent schedules run in the
/// server's time zone; the schedule popup converts to the user's local time.
@JsonSerializable()
class AdkSchedulePreview {
  final String? serverTimeZone;
  @JsonKey(defaultValue: 0)
  final int serverUtcOffsetMinutes;

  /// null when no cron expression was given
  final bool? valid;
  final String? error;

  /// ISO-8601 UTC instants
  @JsonKey(defaultValue: [])
  final List<String> nextRuns;

  const AdkSchedulePreview({
    this.serverTimeZone,
    this.serverUtcOffsetMinutes = 0,
    this.valid,
    this.error,
    this.nextRuns = const [],
  });

  /// The next runs in the device's local time.
  List<DateTime> get nextRunsLocal =>
      nextRuns.map((r) => DateTime.parse(r).toLocal()).toList();

  factory AdkSchedulePreview.fromJson(Map<String, dynamic> json) =>
      _$AdkSchedulePreviewFromJson(json);
  Map<String, dynamic> toJson() => _$AdkSchedulePreviewToJson(this);
}
