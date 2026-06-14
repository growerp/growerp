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

import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'adk_config_service.dart';

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

  bool _scheduleEnabled = false;
  bool _saving = false;
  // Trust foundation: safe-by-default for new agents.
  String _toolMode = 'readOnly'; // readOnly | scoped | full
  String _writePolicy = 'approve'; // block | approve | allow
  // Multi-agent orchestration (Phase 4).
  String _agentRole = 'specialist'; // specialist | coordinator
  String _orchestrationType = 'router'; // router | sequential | parallel | loop
  List<AdkAgentTeamMember> _members = [];
  List<AdkAgentConfig> _allAgents = [];
  bool _teamLoading = false;

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
      _modelCtrl.text = e.modelName ?? 'gemini-2.5-flash';
      _llmProviderCtrl.text = e.llmProvider ?? 'gemini';
      _instructionCtrl.text = e.instruction ?? '';
      _descriptionCtrl.text = e.description ?? '';
      _scheduleCronCtrl.text = e.scheduleExpression ?? '';
      _schedulePromptCtrl.text = e.schedulePrompt ?? '';
      _chatRoomIdCtrl.text = e.scheduleChatRoomId ?? '';
      _scheduleEnabled = e.scheduleEnabled;
      _toolMode = e.toolMode ?? 'readOnly';
      _writePolicy = e.writePolicy ?? 'approve';
      _allowlistCtrl.text = e.serviceAllowlist ?? '';
      _approvalRoomCtrl.text = e.approvalChatRoomId ?? '';
      _agentRole = e.agentRole ?? 'specialist';
      _orchestrationType = e.orchestrationType ?? 'router';
      if (_agentRole != 'specialist' && e.adkAgentConfigId != null) _loadTeam();
    } else {
      _modelCtrl.text = 'gemini-2.5-flash';
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
          SnackBar(content: Text('Add failed: $e'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Remove failed: $e'), backgroundColor: Colors.red),
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleEnabled &&
        _instructionCtrl.text.trim().isEmpty &&
        _schedulePromptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set instruction or schedule prompt — at least one required'),
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
        agentRole: _agentRole,
        orchestrationType: _agentRole == 'specialist' ? null : _orchestrationType,
      );
      final apiKey = _apiKeyCtrl.text.trim();
      final saved = await svc.save(cfg, apiKey: apiKey.isEmpty ? null : apiKey);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text('Save the coordinator first, then re-open it to add team members.',
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
        const Text('Team members', style: TextStyle(fontWeight: FontWeight.w600)),
        if (_teamLoading) const LinearProgressIndicator(),
        if (_members.isEmpty && !_teamLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('No members yet — add specialists below.'),
          ),
        ..._members.map((m) => ListTile(
              key: Key('teamMember_${m.memberConfigId}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(m.memberName ?? m.memberConfigId ?? '?'),
              subtitle: m.memberDescription != null
                  ? Text(m.memberDescription!,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: IconButton(
                key: Key('removeMember_${m.memberConfigId}'),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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
              key: const Key('addTeamMember'),
              enabled: !_teamLoading,
              tooltip: 'Add specialist',
              itemBuilder: (_) => available
                  .map((a) => PopupMenuItem<String>(
                        value: a.adkAgentConfigId,
                        child: Text(a.agentName ?? a.adkAgentConfigId ?? '?'),
                      ))
                  .toList(),
              onSelected: (v) => _addMember(v),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add specialist…'),
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
      key: const Key('AdkAgentConfigDialog'),
      insetPadding: const EdgeInsets.all(10),
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
                        key: const Key('agentName'),
                        controller: _nameCtrl,
                        maxLength: 63,
                        decoration:
                            const InputDecoration(labelText: 'Agent name *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('modelName'),
                        controller: _modelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'gemini-2.5-flash',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('llmProvider'),
                        controller: _llmProviderCtrl,
                        decoration: const InputDecoration(
                          labelText: 'LLM Provider',
                          hintText: 'gemini',
                          helperText:
                              'Provider configured in System Setup (gemini, openai, anthropic, …)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('instruction'),
                        controller: _instructionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Instruction (system prompt)',
                          hintText: 'You are a helpful assistant…',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('description'),
                        controller: _descriptionCtrl,
                        maxLength: 255,
                        decoration: const InputDecoration(
                            labelText: 'Description (optional)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('apiKey'),
                        controller: _apiKeyCtrl,
                        decoration: InputDecoration(
                          labelText: isNew
                              ? 'Google API key (leave blank to use server default)'
                              : 'New API key (leave blank to keep existing)',
                        ),
                        obscureText: true,
                      ),
                      const Divider(height: 24),
                      const Text('Permissions & governance',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: const Key('toolMode'),
                        initialValue: _toolMode,
                        decoration: const InputDecoration(
                          labelText: 'Tool access',
                          helperText:
                              'readOnly: queries only · scoped: allow-listed services · full: any service',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'readOnly', child: Text('Read-only')),
                          DropdownMenuItem(
                              value: 'scoped', child: Text('Scoped (allow-list)')),
                          DropdownMenuItem(value: 'full', child: Text('Full')),
                        ],
                        onChanged: (v) =>
                            setState(() => _toolMode = v ?? 'readOnly'),
                      ),
                      if (_toolMode == 'scoped') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('serviceAllowlist'),
                          controller: _allowlistCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Allowed services',
                            hintText: 'growerp.*#get*, mantle.order.*',
                            helperText:
                                'Comma-separated service-name globs (* wildcard)',
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: const Key('writePolicy'),
                        initialValue: _writePolicy,
                        decoration: const InputDecoration(
                          labelText: 'Write policy',
                          helperText:
                              'How write (create/update/…) actions are handled',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'block', child: Text('Block writes')),
                          DropdownMenuItem(
                              value: 'approve',
                              child: Text('Require approval')),
                          DropdownMenuItem(
                              value: 'allow', child: Text('Allow (auto-run)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _writePolicy = v ?? 'approve'),
                      ),
                      if (_writePolicy == 'approve') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('approvalChatRoomId'),
                          controller: _approvalRoomCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Approval chat room ID (optional)',
                            hintText: 'Where approval requests are posted',
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      const Text('Team / orchestration',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: const Key('agentRole'),
                        initialValue: _agentRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          helperText:
                              'specialist: does the work · coordinator: delegates to a team of specialists',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'specialist', child: Text('Specialist')),
                          DropdownMenuItem(
                              value: 'coordinator', child: Text('Coordinator (team)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _agentRole = v ?? 'specialist'),
                      ),
                      if (_agentRole != 'specialist') ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: const Key('orchestrationType'),
                          initialValue: _orchestrationType,
                          decoration: const InputDecoration(
                            labelText: 'Orchestration',
                            helperText:
                                'router: the LLM picks specialists (sequential/parallel/loop: Phase 4b)',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'router', child: Text('Router (LLM picks)')),
                            DropdownMenuItem(value: 'sequential', child: Text('Sequential')),
                            DropdownMenuItem(value: 'parallel', child: Text('Parallel')),
                            DropdownMenuItem(value: 'loop', child: Text('Loop')),
                          ],
                          onChanged: (v) =>
                              setState(() => _orchestrationType = v ?? 'router'),
                        ),
                        const SizedBox(height: 8),
                        _teamMembersSection(isNew: widget.existing == null),
                      ],
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable scheduled runs'),
                        value: _scheduleEnabled,
                        onChanged: (v) =>
                            setState(() => _scheduleEnabled = v),
                      ),
                      if (_scheduleEnabled) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('scheduleExpression'),
                                controller: _scheduleCronCtrl,
                                decoration: const InputDecoration(
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
                              icon: const Icon(Icons.schedule),
                              onSelected: (v) =>
                                  setState(() => _scheduleCronCtrl.text = v),
                              itemBuilder: (_) => _cronHints
                                  .map(
                                    (h) => PopupMenuItem<String>(
                                      value: h.$2,
                                      child: Text('${h.$1}  (${h.$2})'),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('schedulePrompt'),
                          controller: _schedulePromptCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Prompt for each scheduled run',
                            hintText: 'What is the current time?',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('scheduleChatRoomId'),
                          controller: _chatRoomIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Chat room ID for delivery (optional)',
                            hintText: 'Leave blank to log only',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('AdkAgentConfigCancel'),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('AdkAgentConfigSave'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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
