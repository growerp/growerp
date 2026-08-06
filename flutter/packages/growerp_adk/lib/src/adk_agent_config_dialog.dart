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

import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'adk_config_service.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

/// Dialog to create or edit an [AdkAgentConfig].
/// Returns the saved [AdkAgentConfig] (with the generated ID) or null if cancelled.
class AdkAgentConfigDialog extends StatefulWidget {
  final AdkAgentConfig? existing;

  const AdkAgentConfigDialog({super.key, this.existing});

  static Future<AdkAgentConfig?> show(
    BuildContext context, {
    AdkAgentConfig? existing,
  }) =>
      showDialog<AdkAgentConfig>(
        context: context,
        builder: (_) => AdkAgentConfigDialog(existing: existing),
      );

  @override
  State<AdkAgentConfigDialog> createState() => _AdkAgentConfigDialogState();
}

class _AdkAgentConfigDialogState extends State<AdkAgentConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _llmProviderCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _scheduleCronCtrl = TextEditingController();
  final _schedulePromptCtrl = TextEditingController();
  final _chatRoomIdCtrl = TextEditingController();
  final _allowlistCtrl = TextEditingController();
  final _approvalRoomCtrl = TextEditingController();
  final _loopMaxCtrl = TextEditingController();

  bool _scheduleEnabled = false;
  bool _saving = false;
  // Trust foundation: safe-by-default for new agents.
  String _toolMode = 'readOnly'; // readOnly | scoped | full
  String _writePolicy = 'approve'; // block | approve | allow
  bool _websiteChat = false; // answers the public website chat
  // Multi-agent orchestration (Phase 4).
  String _agentRole = 'specialist'; // specialist | coordinator
  String _orchestrationType = 'router'; // router | sequential | parallel | loop
  List<AdkAgentTeamMember> _members = [];
  List<AdkAgentConfig> _allAgents = [];
  bool _teamLoading = false;
  // External MCP servers attached to this agent (+ the tenant registry to add from).
  List<AdkAgentMcpServer> _attachedServers = [];
  List<AdkMcpServer> _allServers = [];
  bool _mcpLoading = false;

  static const _geminiModels = ['gemini-2.5-flash', 'gemini-2.5-flash-lite'];

  static const _cronHints = [
    ('Every minute', '0 * * * * ?'),
    ('Every 5 minutes', '0 */5 * * * ?'),
    ('Every hour', '0 0 * * * ?'),
    ('Every day at 9am', '0 0 9 * * ?'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.agentName ?? '';
      _modelCtrl.text = e.modelName ?? 'gemini-2.5-flash-lite';
      _llmProviderCtrl.text = e.llmProvider ?? 'gemini';
      _instructionCtrl.text = e.instruction ?? '';
      _descriptionCtrl.text = e.description ?? '';
      _scheduleCronCtrl.text = e.scheduleExpression ?? '';
      _schedulePromptCtrl.text = e.schedulePrompt ?? '';
      _chatRoomIdCtrl.text = e.scheduleChatRoomId ?? '';
      _scheduleEnabled = e.scheduleEnabled;
      _toolMode = e.toolMode ?? 'readOnly';
      _writePolicy = e.writePolicy ?? 'approve';
      _websiteChat = e.websiteChat;
      _allowlistCtrl.text = e.serviceAllowlist ?? '';
      _approvalRoomCtrl.text = e.approvalChatRoomId ?? '';
      _agentRole = e.agentRole ?? 'specialist';
      _orchestrationType = e.orchestrationType ?? 'router';
      _loopMaxCtrl.text = e.loopMaxIterations?.toString() ?? '';
      if (_agentRole != 'specialist' && e.adkAgentConfigId != null) _loadTeam();
      if (e.adkAgentConfigId != null) _loadMcpServers();
    } else {
      _modelCtrl.text = 'gemini-2.5-flash-lite';
      _llmProviderCtrl.text = 'gemini';
    }
  }

  /// Load this coordinator's members + the company's other agents (to add from).
  Future<void> _loadTeam() async {
    final id = widget.existing?.adkAgentConfigId;
    if (id == null) return;
    setState(() => _teamLoading = true);
    try {
      final svc = await AdkConfigService.create();
      final members = await svc.teamMembers(id);
      final all = await svc.list();
      if (mounted) {
        setState(() {
          _members = members;
          _allAgents = all;
        });
      }
    } catch (_) {
      // best-effort; team UI just stays empty
    } finally {
      if (mounted) setState(() => _teamLoading = false);
    }
  }

  Future<void> _addMember(String memberConfigId) async {
    final id = widget.existing?.adkAgentConfigId;
    if (id == null) return;
    setState(() => _teamLoading = true);
    try {
      final svc = await AdkConfigService.create();
      await svc.addTeamMember(id, memberConfigId, sequenceNum: _members.length);
      await _loadTeam();
    } catch (e) {
      if (mounted) {
        setState(() => _teamLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_addFailedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeMember(String teamMemberId) async {
    setState(() => _teamLoading = true);
    try {
      final svc = await AdkConfigService.create();
      await svc.removeTeamMember(teamMemberId);
      await _loadTeam();
    } catch (e) {
      if (mounted) {
        setState(() => _teamLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_removeFailedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Load this agent's attached external MCP servers + the tenant registry to add from.
  Future<void> _loadMcpServers() async {
    final id = widget.existing?.adkAgentConfigId;
    if (id == null) return;
    setState(() => _mcpLoading = true);
    try {
      final svc = await AdkConfigService.create();
      final attached = await svc.attachedServers(id);
      final all = await svc.listMcpServers();
      if (mounted) {
        setState(() {
          _attachedServers = attached;
          _allServers = all;
        });
      }
    } catch (_) {
      // best-effort; the MCP section just stays empty
    } finally {
      if (mounted) setState(() => _mcpLoading = false);
    }
  }

  Future<void> _attachServer(String adkMcpServerId) async {
    final id = widget.existing?.adkAgentConfigId;
    if (id == null) return;
    setState(() => _mcpLoading = true);
    try {
      final svc = await AdkConfigService.create();
      await svc.attachServer(id, adkMcpServerId,
          sequenceNum: _attachedServers.length);
      await _loadMcpServers();
    } catch (e) {
      if (mounted) {
        setState(() => _mcpLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_attachFailedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _detachServer(String adkAgentMcpServerId) async {
    setState(() => _mcpLoading = true);
    try {
      final svc = await AdkConfigService.create();
      await svc.detachServer(adkAgentMcpServerId);
      // Drop the row locally instead of re-reading: the delete either succeeded
      // (so the tile must go) or threw. A re-read has been seen on CI to still
      // return the detached row, which put the tile back.
      if (mounted) {
        setState(() {
          _attachedServers = _attachedServers
              .where((s) => s.adkAgentMcpServerId != adkAgentMcpServerId)
              .toList();
          _mcpLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mcpLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_detachFailedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _llmProviderCtrl.dispose();
    _instructionCtrl.dispose();
    _descriptionCtrl.dispose();
    _apiKeyCtrl.dispose();
    _scheduleCronCtrl.dispose();
    _schedulePromptCtrl.dispose();
    _chatRoomIdCtrl.dispose();
    _allowlistCtrl.dispose();
    _approvalRoomCtrl.dispose();
    _loopMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleEnabled &&
        _instructionCtrl.text.trim().isEmpty &&
        _schedulePromptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AdkLocalizations.of(context)!.adk_setInstructionOrSchedule),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final svc = await AdkConfigService.create();
      final cfg = AdkAgentConfig(
        adkAgentConfigId: widget.existing?.adkAgentConfigId,
        agentName: _nameCtrl.text.trim(),
        modelName: _modelCtrl.text.trim(),
        llmProvider: _llmProviderCtrl.text.trim().isEmpty
            ? 'gemini'
            : _llmProviderCtrl.text.trim(),
        instruction: _instructionCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        scheduleExpression:
            _scheduleEnabled ? _scheduleCronCtrl.text.trim() : null,
        scheduleEnabled: _scheduleEnabled,
        schedulePrompt:
            _scheduleEnabled ? _schedulePromptCtrl.text.trim() : null,
        scheduleChatRoomId:
            _chatRoomIdCtrl.text.trim().isEmpty
                ? null
                : _chatRoomIdCtrl.text.trim(),
        toolMode: _toolMode,
        serviceAllowlist: _toolMode == 'scoped'
            ? _allowlistCtrl.text.trim()
            : null,
        writePolicy: _writePolicy,
        approvalChatRoomId: _approvalRoomCtrl.text.trim().isEmpty
            ? null
            : _approvalRoomCtrl.text.trim(),
        websiteChat: _websiteChat,
        agentRole: _agentRole,
        orchestrationType: _agentRole == 'specialist' ? null : _orchestrationType,
        loopMaxIterations:
            (_agentRole != 'specialist' && _orchestrationType == 'loop')
                ? int.tryParse(_loopMaxCtrl.text.trim())
                : null,
      );
      final apiKey = _apiKeyCtrl.text.trim();
      final saved = await svc.save(cfg, apiKey: apiKey.isEmpty ? null : apiKey);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_saveFailedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Current members + an add-from-available picker. Members can only be managed on a
  /// coordinator that already exists (needs an id); for a new one, prompt to save first.
  Widget _teamMembersSection({required bool isNew}) {
    if (isNew) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(AdkLocalizations.of(context)!.adk_saveTheCoordinatorFirst,
            style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    final selfId = widget.existing?.adkAgentConfigId;
    final memberIds = _members.map((m) => m.memberConfigId).toSet();
    final available = _allAgents
        .where((a) =>
            a.adkAgentConfigId != selfId &&
            !memberIds.contains(a.adkAgentConfigId) &&
            (a.agentRole ?? 'specialist') == 'specialist')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AdkLocalizations.of(context)!.adk_teamMembers, style: TextStyle(fontWeight: FontWeight.w600)),
        if (_teamLoading) LinearProgressIndicator(),
        if (_members.isEmpty && !_teamLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(AdkLocalizations.of(context)!.adk_noMembersYetAdd),
          ),
        ..._members.map((m) => ListTile(
              key: Key('teamMember_${m.memberConfigId}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.smart_toy_outlined),
              title: Text(m.memberName ?? m.memberConfigId ?? '?'),
              subtitle: m.memberDescription != null
                  ? Text(m.memberDescription!,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: IconButton(
                key: Key('removeMember_${m.memberConfigId}'),
                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'Remove',
                onPressed: _teamLoading || m.adkAgentTeamMemberId == null
                    ? null
                    : () => _removeMember(m.adkAgentTeamMemberId!),
              ),
            )),
        if (available.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              key: Key('addTeamMember'),
              enabled: !_teamLoading,
              tooltip: 'Add specialist',
              itemBuilder: (_) => available
                  .map((a) => PopupMenuItem<String>(
                        value: a.adkAgentConfigId,
                        child: Text(a.agentName ?? a.adkAgentConfigId ?? '?'),
                      ))
                  .toList(),
              onSelected: (v) => _addMember(v),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(AdkLocalizations.of(context)!.adk_addSpecialist),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Attached external MCP servers + a picker of the tenant registry. Only manageable on a
  /// saved agent (needs an id); for a new one, prompt to save first.
  Widget _mcpServersSection({required bool isNew}) {
    // The built-in Moqui MCP server is hardcoded into every agent — show it
    // first as a read-only, always-attached tile (no detach).
    final builtinTile = ListTile(
      key: Key('builtinMcpServer'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.verified,
          color: Theme.of(context).colorScheme.primary),
      title: Text(AdkLocalizations.of(context)!.adk_moquiBuiltIn),
      subtitle: Text(AdkLocalizations.of(context)!.adk_alwaysAttachedReadOnly),
    );
    if (isNew) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          builtinTile,
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(AdkLocalizations.of(context)!.adk_saveTheAgentFirst,
                style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      );
    }
    final attachedIds =
        _attachedServers.map((s) => s.adkMcpServerId).toSet();
    final available = _allServers
        .where((s) => s.enabled && !attachedIds.contains(s.adkMcpServerId))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        builtinTile,
        if (_mcpLoading) LinearProgressIndicator(),
        if (_attachedServers.isEmpty && !_mcpLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(AdkLocalizations.of(context)!.adk_noExternalMcpServers),
          ),
        ..._attachedServers.map((s) => ListTile(
              key: Key('mcpServer_${s.adkMcpServerId}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dns_outlined),
              title: Text(s.serverName ?? s.adkMcpServerId ?? '?'),
              subtitle: s.url != null
                  ? Text(s.url!, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: IconButton(
                key: Key('detachMcpServer_${s.adkMcpServerId}'),
                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'Detach',
                onPressed: _mcpLoading || s.adkAgentMcpServerId == null
                    ? null
                    : () => _detachServer(s.adkAgentMcpServerId!),
              ),
            )),
        if (available.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              key: Key('attachMcpServer'),
              enabled: !_mcpLoading,
              tooltip: 'Attach MCP server',
              itemBuilder: (_) => available
                  .map((s) => PopupMenuItem<String>(
                        value: s.adkMcpServerId,
                        child: Text(s.serverName ?? s.adkMcpServerId ?? '?'),
                      ))
                  .toList(),
              onSelected: (v) => _attachServer(v),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(AdkLocalizations.of(context)!.adk_attachMcpServer),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final id = widget.existing?.adkAgentConfigId ?? 'new';
    return Dialog(
      key: Key('AdkAgentConfigDialog'),
      insetPadding: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'ADK Agent #$id',
        width: 500,
        height: _scheduleEnabled ? 760 : 600,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        key: Key('agentName'),
                        controller: _nameCtrl,
                        maxLength: 63,
                        decoration:
                            InputDecoration(labelText: 'Agent name *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        key: Key('modelName'),
                        controller: _modelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Model',
                          hintText: 'gemini-2.5-flash-lite',
                          suffixIcon: PopupMenuButton<String>(
                            key: Key('modelNameMenu'),
                            tooltip: 'Pick a Gemini model',
                            icon: Icon(Icons.arrow_drop_down),
                            itemBuilder: (context) => _geminiModels
                                .map((m) => PopupMenuItem<String>(
                                      value: m,
                                      child: Text(m),
                                    ))
                                .toList(),
                            onSelected: (m) =>
                                setState(() => _modelCtrl.text = m),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        key: Key('llmProvider'),
                        controller: _llmProviderCtrl,
                        decoration: InputDecoration(
                          labelText: 'LLM Provider',
                          hintText: 'gemini',
                          helperText:
                              'Provider configured in System Setup (gemini, openai, anthropic, …)',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        key: Key('instruction'),
                        controller: _instructionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Instruction (system prompt)',
                          hintText: 'You are a helpful assistant…',
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        key: Key('description'),
                        controller: _descriptionCtrl,
                        maxLength: 255,
                        decoration: InputDecoration(
                            labelText: 'Description (optional)'),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        key: Key('apiKey'),
                        controller: _apiKeyCtrl,
                        decoration: InputDecoration(
                          labelText: isNew
                              ? 'Google API key (leave blank to use server default)'
                              : 'New API key (leave blank to keep existing)',
                        ),
                        obscureText: true,
                      ),
                      Divider(height: 24),
                      Text(AdkLocalizations.of(context)!.adk_permissionsGovernance,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: Key('toolMode'),
                        initialValue: _toolMode,
                        decoration: InputDecoration(
                          labelText: 'Tool access',
                          helperText:
                              'readOnly: queries only · scoped: allow-listed services · full: any service',
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'readOnly', child: Text(AdkLocalizations.of(context)!.adk_readOnly)),
                          DropdownMenuItem(
                              value: 'scoped', child: Text(AdkLocalizations.of(context)!.adk_scopedAllowList)),
                          DropdownMenuItem(value: 'full', child: Text('Full')),
                        ],
                        onChanged: (v) =>
                            setState(() => _toolMode = v ?? 'readOnly'),
                      ),
                      if (_toolMode == 'scoped') ...[
                        SizedBox(height: 8),
                        TextFormField(
                          key: Key('serviceAllowlist'),
                          controller: _allowlistCtrl,
                          decoration: InputDecoration(
                            labelText: 'Allowed services',
                            hintText: 'growerp.*#get*, mantle.order.*',
                            helperText:
                                'Comma-separated service-name globs (* wildcard)',
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: Key('writePolicy'),
                        initialValue: _writePolicy,
                        decoration: InputDecoration(
                          labelText: 'Write policy',
                          helperText:
                              'How write (create/update/…) actions are handled',
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'block', child: Text(AdkLocalizations.of(context)!.adk_blockWrites)),
                          DropdownMenuItem(
                              value: 'approve',
                              child: Text(AdkLocalizations.of(context)!.adk_requireApproval)),
                          DropdownMenuItem(
                              value: 'allow', child: Text(AdkLocalizations.of(context)!.adk_allowAutoRun)),
                        ],
                        onChanged: (v) =>
                            setState(() => _writePolicy = v ?? 'approve'),
                      ),
                      if (_writePolicy == 'approve') ...[
                        SizedBox(height: 8),
                        TextFormField(
                          key: Key('approvalChatRoomId'),
                          controller: _approvalRoomCtrl,
                          decoration: InputDecoration(
                            labelText: 'Approval chat room ID (optional)',
                            hintText: 'Where approval requests are posted',
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      CheckboxListTile(
                        key: Key('websiteChat'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _websiteChat,
                        title: Text(AdkLocalizations.of(context)!.adk_answerWebsiteChat),
                        subtitle: Text(AdkLocalizations.of(context)!.adk_thisAgentRepliesTo,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (v) =>
                            setState(() => _websiteChat = v ?? false),
                      ),
                      Divider(height: 24),
                      Text(AdkLocalizations.of(context)!.adk_teamOrchestration,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: Key('agentRole'),
                        initialValue: _agentRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          helperText:
                              'specialist: does the work · coordinator: delegates to a team of specialists',
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'specialist', child: Text('Specialist')),
                          DropdownMenuItem(
                              value: 'coordinator', child: Text(AdkLocalizations.of(context)!.adk_coordinatorTeam)),
                        ],
                        onChanged: (v) =>
                            setState(() => _agentRole = v ?? 'specialist'),
                      ),
                      if (_agentRole != 'specialist') ...[
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: Key('orchestrationType'),
                          initialValue: _orchestrationType,
                          decoration: InputDecoration(
                            labelText: 'Orchestration',
                            helperText:
                                'router: the LLM picks specialists (sequential/parallel/loop: Phase 4b)',
                          ),
                          items: [
                            DropdownMenuItem(value: 'router', child: Text(AdkLocalizations.of(context)!.adk_routerLlmPicks)),
                            DropdownMenuItem(value: 'sequential', child: Text('Sequential')),
                            DropdownMenuItem(value: 'parallel', child: Text('Parallel')),
                            DropdownMenuItem(value: 'loop', child: Text('Loop')),
                          ],
                          onChanged: (v) =>
                              setState(() => _orchestrationType = v ?? 'router'),
                        ),
                        if (_orchestrationType == 'loop') ...[
                          SizedBox(height: 8),
                          TextFormField(
                            key: Key('loopMaxIterations'),
                            controller: _loopMaxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max loop iterations',
                              hintText: '3',
                              helperText: 'Safety cap for the loop workflow',
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        _teamMembersSection(isNew: widget.existing == null),
                      ],
                      Divider(height: 24),
                      Text(AdkLocalizations.of(context)!.adk_mcpServers,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'External tool servers (SSE / HTTP) this agent may use. '
                        'Register them in the MCP Servers screen first.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      _mcpServersSection(isNew: widget.existing == null),
                      Divider(height: 24),
                      SwitchListTile(
                        key: Key('scheduleEnabled'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(AdkLocalizations.of(context)!.adk_enableScheduledRuns),
                        value: _scheduleEnabled,
                        onChanged: (v) =>
                            setState(() => _scheduleEnabled = v),
                      ),
                      if (_scheduleEnabled) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: Key('scheduleExpression'),
                                controller: _scheduleCronCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Cron expression *',
                                  hintText: '0 * * * * ?',
                                ),
                                validator: (v) => (_scheduleEnabled &&
                                        (v == null || v.trim().isEmpty))
                                    ? 'Required when schedule enabled'
                                    : null,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Quick schedules',
                              icon: Icon(Icons.schedule),
                              onSelected: (v) =>
                                  setState(() => _scheduleCronCtrl.text = v),
                              itemBuilder: (_) => _cronHints
                                  .map(
                                    (h) => PopupMenuItem<String>(
                                      value: h.$2,
                                      child: Text(AdkLocalizations.of(context)!.adk_h1H2(h.$1.toString(), h.$2.toString())),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          key: Key('schedulePrompt'),
                          controller: _schedulePromptCtrl,
                          decoration: InputDecoration(
                            labelText: 'Prompt for each scheduled run',
                            hintText: 'What is the current time?',
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          key: Key('scheduleChatRoomId'),
                          controller: _chatRoomIdCtrl,
                          decoration: InputDecoration(
                            labelText: 'Chat room ID for delivery (optional)',
                            hintText: 'Leave blank to log only',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: Key('AdkAgentConfigCancel'),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  FilledButton(
                    key: Key('AdkAgentConfigSave'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
