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

import 'dart:convert';

import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

class AdkConfigService {
  final RestClient _client;

  AdkConfigService._(this._client);

  static Future<AdkConfigService> create() async {
    final client = RestClient(await buildDioClient());
    return AdkConfigService._(client);
  }

  /// Tenant settings, used to see which LLM providers have an API key.
  Future<SystemSettings> systemSettings() => _client.getSystemSettings();

  Future<List<AdkAgentConfig>> list({String? search}) async {
    final result = await _client.getAdkAgentConfigs(search: search);
    return result.adkAgentConfigs;
  }

  Future<AdkAgentConfig> save(AdkAgentConfig cfg, {String? apiKey}) async {
    if (cfg.adkAgentConfigId == null || cfg.adkAgentConfigId!.isEmpty) {
      return _client.createAdkAgentConfig(
        agentName: cfg.agentName,
        modelName: cfg.modelName,
        llmProvider: cfg.llmProvider,
        apiKey: apiKey,
        instruction: cfg.instruction,
        description: cfg.description,
        scheduleExpression: cfg.scheduleExpression,
        scheduleEnabled: cfg.scheduleEnabled,
        schedulePrompt: cfg.schedulePrompt,
        scheduleChatRoomId: cfg.scheduleChatRoomId,
        toolMode: cfg.toolMode,
        serviceAllowlist: cfg.serviceAllowlist,
        writePolicy: cfg.writePolicy,
        approvalChatRoomId: cfg.approvalChatRoomId,
        agentRole: cfg.agentRole,
        orchestrationType: cfg.orchestrationType,
        loopMaxIterations: cfg.loopMaxIterations,
        teamName: cfg.teamName,
      );
    }
    return _client.updateAdkAgentConfig(
      adkAgentConfigId: cfg.adkAgentConfigId!,
      agentName: cfg.agentName,
      modelName: cfg.modelName,
      llmProvider: cfg.llmProvider,
      apiKey: apiKey,
      instruction: cfg.instruction,
      description: cfg.description,
      scheduleExpression: cfg.scheduleExpression,
      scheduleEnabled: cfg.scheduleEnabled,
      schedulePrompt: cfg.schedulePrompt,
      scheduleChatRoomId: cfg.scheduleChatRoomId,
      toolMode: cfg.toolMode,
      serviceAllowlist: cfg.serviceAllowlist,
      writePolicy: cfg.writePolicy,
      approvalChatRoomId: cfg.approvalChatRoomId,
      agentRole: cfg.agentRole,
      orchestrationType: cfg.orchestrationType,
      loopMaxIterations: cfg.loopMaxIterations,
      teamName: cfg.teamName,
    );
  }

  Future<void> delete(String configId) async {
    await _client.deleteAdkAgentConfig(adkAgentConfigId: configId);
  }

  /// Opt one of this tenant's own agents in/out of the support app's catalog
  /// promotion review queue. Never makes it visible or usable by another
  /// tenant on its own.
  Future<void> nominateForCatalog(String configId, {bool nominated = true}) =>
      _client.nominateAdkAgentConfig(
        adkAgentConfigId: configId,
        nominated: nominated,
      );

  /// Support-only: the catalog promotion review queue (every tenant's
  /// catalogNominated='Y' agents).
  Future<List<AdkAgentConfig>> nominatedAgents() async {
    final r = await _client.getNominatedAgents();
    return r.agents;
  }

  /// Support-only: clone a nominated tenant agent into the shared "_NA_" catalog.
  Future<void> promoteToCatalog(String configId) =>
      _client.promoteAgentToCatalog(adkAgentConfigId: configId);

  /// Clone the GROWERP marketing agent team into this tenant (idempotent).
  Future<void> enableMarketingTeam() async {
    await _client.enableMarketingAgentTeam();
  }

  /// Load the Agent Control Center demo into this tenant (idempotent).
  Future<void> loadAgentDemo() async {
    await _client.loadAgentDemo();
  }

  /// Load a named production-ready template team (e.g. "GrowERP Operations
  /// Team") into this tenant, independently of the Agent Control demo above
  /// (idempotent). Pass [adkAgentConfigIds] to clone exactly those catalog
  /// functions instead of the whole team.
  Future<void> loadAgentTeam({
    String? teamName,
    List<String>? adkAgentConfigIds,
  }) async {
    await _client.loadAgentTeam(
      teamName: teamName,
      adkAgentConfigIds: adkAgentConfigIds,
    );
  }

  /// The function catalog: every "_NA_" template function across every real
  /// team, plus whether this tenant already has each one.
  Future<List<AdkAgentCatalogFunction>> agentCatalog() async {
    final r = await _client.getAdkAgentCatalog();
    return r.functions;
  }

  /// Feasibility-checked "suggest a new function": checks a free-text
  /// description against real services and [screenCatalogJson] (the running
  /// app's own screen catalog, so a "just navigate there" outcome can be
  /// recognised). Never creates anything. [ownerPartyId] is a support-only
  /// override to test on behalf of a specific tenant — ignored for anyone not
  /// in GROWERP_M_SYSTEM.
  Future<AdkFunctionSuggestion> suggestFunction(
    String description, {
    String? screenCatalogJson,
    String? ownerPartyId,
  }) =>
      _client.suggestAgentFunction(
        description: description,
        screenCatalogJson: screenCatalogJson,
        ownerPartyId: ownerPartyId,
      );

  // ── Phase 4: team membership ───────────────────────────────────────────────
  Future<List<AdkAgentTeamMember>> teamMembers(String coordinatorConfigId) async {
    final r = await _client.getAdkAgentTeam(coordinatorConfigId: coordinatorConfigId);
    return r.members;
  }

  Future<void> addTeamMember(String coordinatorConfigId, String memberConfigId,
          {int? sequenceNum, String delegationMode = 'tool'}) async =>
      _client.createAdkAgentTeam(
          coordinatorConfigId: coordinatorConfigId,
          memberConfigId: memberConfigId,
          sequenceNum: sequenceNum,
          delegationMode: delegationMode);

  Future<void> removeTeamMember(String adkAgentTeamMemberId) async =>
      _client.deleteAdkAgentTeam(adkAgentTeamMemberId: adkAgentTeamMemberId);

  /// Download a whole team (agents + delegation edges) as one JSON payload.
  /// A null [teamName] downloads the untagged "Other agents" bucket.
  Future<AdkAgentTeamExport> exportTeam(String? teamName) async =>
      _client.getAdkAgentTeamExport(teamName: teamName);

  /// Upload a team JSON payload previously produced by [exportTeam].
  Future<AdkAgentTeamImportResult> importTeam(String jsonText) async =>
      _client.postAdkAgentTeamImport(jsonText: jsonText);

  // ── System settings (read-only here; used for tool-auth status badges) ─────
  Future<SystemSettings> getSystemSettings() => _client.getSystemSettings();

  // ── External MCP server registry (tenant-level) ────────────────────────────
  Future<List<AdkMcpServer>> listMcpServers({String? search}) async {
    final r = await _client.getAdkMcpServers(search: search);
    return r.adkMcpServers;
  }

  Future<AdkMcpServer> saveMcpServer(AdkMcpServer server) async {
    final headersJson =
        (server.headers != null && server.headers!.isNotEmpty)
            ? jsonEncode(server.headers)
            : null;
    if (server.adkMcpServerId == null || server.adkMcpServerId!.isEmpty) {
      return _client.createAdkMcpServer(
        serverName: server.serverName ?? '',
        url: server.url ?? '',
        transport: server.transport,
        headersJson: headersJson,
        enabled: server.enabled,
      );
    }
    return _client.updateAdkMcpServer(
      adkMcpServerId: server.adkMcpServerId!,
      serverName: server.serverName,
      url: server.url,
      transport: server.transport,
      headersJson: headersJson,
      enabled: server.enabled,
    );
  }

  Future<void> deleteMcpServer(String adkMcpServerId) async =>
      _client.deleteAdkMcpServer(adkMcpServerId: adkMcpServerId);

  // ── Attach / detach an MCP server to an agent ──────────────────────────────
  Future<List<AdkAgentMcpServer>> attachedServers(String configId) async {
    final r = await _client.getAdkAgentMcpServers(configId: configId);
    return r.servers;
  }

  Future<void> attachServer(String configId, String adkMcpServerId,
          {int? sequenceNum}) async =>
      _client.createAdkAgentMcpServer(
          configId: configId,
          adkMcpServerId: adkMcpServerId,
          sequenceNum: sequenceNum);

  Future<void> detachServer(String adkAgentMcpServerId) async =>
      _client.deleteAdkAgentMcpServer(adkAgentMcpServerId: adkAgentMcpServerId);
}
