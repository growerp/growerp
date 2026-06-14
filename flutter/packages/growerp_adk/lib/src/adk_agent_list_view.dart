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
import 'adk_agent_config_dialog.dart';
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final list = await svc.list(search: _search.isEmpty ? null : _search);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete agent?'),
        content: Text('Delete "${cfg.agentName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
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
    // No AppBar — title comes from the app shell. Refresh moves to the search line;
    // add is a FAB. Same design as the user list.
    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search agents...',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
          actions: [
            IconButton(
              key: const Key('refreshAdkAgents'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              _buildBody(),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  key: const Key('addAdkAgent'),
                  heroTag: 'adkAgentAdd',
                  onPressed: _create,
                  tooltip: 'New agent',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
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

    final phone = isAPhone(context);
    final cs = Theme.of(context).colorScheme;

    final columns = phone
        ? const [
            StyledColumn(header: '', flex: 1),
            StyledColumn(header: 'Info', flex: 5),
            StyledColumn(header: '', flex: 2),
          ]
        : const [
            StyledColumn(header: '', flex: 1),
            StyledColumn(header: 'Name', flex: 2),
            StyledColumn(header: 'Model', flex: 2),
            StyledColumn(header: 'Instruction', flex: 4),
            StyledColumn(header: 'Schedule', flex: 2),
            StyledColumn(header: '', flex: 1),
          ];

    final rows = _configs.map((cfg) {
      final hasSchedule = cfg.scheduleEnabled &&
          cfg.scheduleExpression != null &&
          cfg.scheduleExpression!.isNotEmpty;

      final avatar = CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        child: Icon(Icons.smart_toy, color: cs.onSecondaryContainer),
      );

      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _edit(cfg),
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 20, color: cs.error),
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _delete(cfg),
          ),
        ],
      );

      if (phone) {
        return [
          avatar,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cfg.agentName ?? '(unnamed)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                cfg.modelName ?? 'gemini-2.5-flash',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              if (cfg.instruction != null && cfg.instruction!.isNotEmpty)
                Text(
                  cfg.instruction!.length > 60
                      ? '${cfg.instruction!.substring(0, 60)}…'
                      : cfg.instruction!,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
            ],
          ),
          actions,
        ];
      }

      return [
        avatar,
        Text(cfg.agentName ?? '(unnamed)'),
        Text(
          cfg.modelName ?? 'gemini-2.5-flash',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        Text(
          cfg.instruction != null && cfg.instruction!.length > 60
              ? '${cfg.instruction!.substring(0, 60)}…'
              : cfg.instruction ?? '',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        hasSchedule
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    cfg.scheduleExpression!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
        actions,
      ];
    }).toList();

    return StyledDataTable(
      columns: columns,
      rows: rows,
      scrollController: _scrollController,
      rowHeight: phone ? 80 : 56,
      onRowTap: (index) => _edit(_configs[index]),
    );
  }
}
