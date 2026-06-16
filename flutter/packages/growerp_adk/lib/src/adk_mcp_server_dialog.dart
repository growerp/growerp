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

/// Dialog to create or edit an [AdkMcpServer] (a tenant-registered external MCP server).
/// Returns the saved [AdkMcpServer] or null if cancelled.
class AdkMcpServerDialog extends StatefulWidget {
  final AdkMcpServer? existing;

  const AdkMcpServerDialog({super.key, this.existing});

  static Future<AdkMcpServer?> show(
    BuildContext context, {
    AdkMcpServer? existing,
  }) =>
      showDialog<AdkMcpServer>(
        context: context,
        builder: (_) => AdkMcpServerDialog(existing: existing),
      );

  @override
  State<AdkMcpServerDialog> createState() => _AdkMcpServerDialogState();
}

class _AdkMcpServerDialogState extends State<AdkMcpServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _transport = 'sse'; // sse | http
  bool _enabled = true;
  bool _saving = false;

  /// Header rows the user enters (name + value). Sent on connect; write-only —
  /// the server never returns existing header values.
  final List<(TextEditingController, TextEditingController)> _headers = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.serverName ?? '';
      _urlCtrl.text = e.url ?? '';
      _transport = e.transport ?? 'sse';
      _enabled = e.enabled;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    for (final h in _headers) {
      h.$1.dispose();
      h.$2.dispose();
    }
    super.dispose();
  }

  void _addHeaderRow() => setState(() =>
      _headers.add((TextEditingController(), TextEditingController())));

  void _removeHeaderRow(int i) => setState(() {
        _headers[i].$1.dispose();
        _headers[i].$2.dispose();
        _headers.removeAt(i);
      });

  Map<String, String> _collectHeaders() {
    final map = <String, String>{};
    for (final h in _headers) {
      final k = h.$1.text.trim();
      final v = h.$2.text.trim();
      if (k.isNotEmpty) map[k] = v;
    }
    return map;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final svc = await AdkConfigService.create();
      final headers = _collectHeaders();
      final server = AdkMcpServer(
        adkMcpServerId: widget.existing?.adkMcpServerId,
        serverName: _nameCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
        transport: _transport,
        headers: headers.isEmpty ? null : headers,
        enabled: _enabled,
      );
      final saved = await svc.saveMcpServer(server);
      if (mounted) Navigator.of(context).pop(saved);
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

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final id = widget.existing?.adkMcpServerId ?? 'new';
    return Dialog(
      key: const Key('AdkMcpServerDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'MCP Server #$id',
        width: 500,
        height: 560,
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
                        key: const Key('serverName'),
                        controller: _nameCtrl,
                        maxLength: 63,
                        decoration:
                            const InputDecoration(labelText: 'Server name *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('serverUrl'),
                        controller: _urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL *',
                          hintText: 'https://host/mcp/sse',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: const Key('transport'),
                        initialValue: _transport,
                        decoration: const InputDecoration(
                          labelText: 'Transport',
                          helperText: 'sse: Server-Sent Events · http: streamable HTTP',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'sse', child: Text('SSE')),
                          DropdownMenuItem(value: 'http', child: Text('HTTP (streamable)')),
                        ],
                        onChanged: (v) => setState(() => _transport = v ?? 'sse'),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Auth headers',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          TextButton.icon(
                            key: const Key('addHeader'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            onPressed: _addHeaderRow,
                          ),
                        ],
                      ),
                      if (!isNew)
                        const Text(
                          'Existing header values are hidden; re-enter them to change.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ..._headers.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: Key('headerName$i'),
                                  controller: entry.value.$1,
                                  decoration: const InputDecoration(
                                      labelText: 'Header', hintText: 'Authorization'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  key: Key('headerValue$i'),
                                  controller: entry.value.$2,
                                  decoration: const InputDecoration(
                                      labelText: 'Value', hintText: 'Bearer …'),
                                  obscureText: true,
                                ),
                              ),
                              IconButton(
                                key: Key('removeHeader$i'),
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _removeHeaderRow(i),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      SwitchListTile(
                        key: const Key('serverEnabled'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('AdkMcpServerCancel'),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('AdkMcpServerSave'),
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
