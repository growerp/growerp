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
import 'adk_agent_config_dialog.dart';
import 'adk_agent_config_model.dart';
import 'adk_config_service.dart';

/// Screen that lists all ADK agent configs and lets users create / edit / delete them.
///
/// Add to your app's route table:
/// ```dart
/// GoRoute(path: '/adk/agents', builder: (_, __) => const AdkAgentListView())
/// ```
/// or push it directly:
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdkAgentListView()));
/// ```
class AdkAgentListView extends StatefulWidget {
  const AdkAgentListView({super.key});

  @override
  State<AdkAgentListView> createState() => _AdkAgentListViewState();
}

class _AdkAgentListViewState extends State<AdkAgentListView> {
  List<AdkAgentConfig> _configs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final list = await svc.list();
      if (mounted) setState(() => _configs = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await AdkAgentConfigDialog.show(context);
    if (result != null) await _load();
  }

  Future<void> _edit(AdkAgentConfig cfg) async {
    final result = await AdkAgentConfigDialog.show(context, existing: cfg);
    if (result != null) await _load();
  }

  Future<void> _delete(AdkAgentConfig cfg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete agent?'),
        content: Text('Delete "${cfg.agentName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkConfigService.create();
      await svc.delete(cfg.adkAgentConfigId!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADK Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addAdkAgent'),
        onPressed: _create,
        tooltip: 'New agent',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_configs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No agents yet.\nTap + to create your first agent.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _configs.length,
      itemBuilder: (_, i) => _AgentTile(
        config: _configs[i],
        onEdit: () => _edit(_configs[i]),
        onDelete: () => _delete(_configs[i]),
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  final AdkAgentConfig config;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgentTile({
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSchedule = config.scheduleEnabled &&
        config.scheduleExpression != null &&
        config.scheduleExpression!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.smart_toy, color: cs.onSecondaryContainer),
        ),
        title: Text(config.agentName ?? '(unnamed)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.modelName ?? 'gemini-2.0-flash',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            if (config.instruction != null && config.instruction!.isNotEmpty)
              Text(
                config.instruction!.length > 80
                    ? '${config.instruction!.substring(0, 80)}…'
                    : config.instruction!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            if (hasSchedule)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      config.scheduleExpression!,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSchedule)
              Tooltip(
                message: 'Scheduled: ${config.scheduleExpression}',
                child: Icon(Icons.alarm_on, size: 18, color: cs.primary),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: cs.error),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
