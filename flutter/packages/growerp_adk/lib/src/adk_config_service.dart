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
    );
  }

  Future<void> delete(String configId) async {
    await _client.deleteAdkAgentConfig(adkAgentConfigId: configId);
  }

  /// Clone the GROWERP marketing agent team into this tenant (idempotent).
  Future<void> enableMarketingTeam() async {
    await _client.enableMarketingAgentTeam();
  }

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
