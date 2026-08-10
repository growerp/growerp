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
import 'adk_agent_config_dialog.dart';
import 'adk_config_service.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

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

  Future<void> _enableMarketingTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_enableMarketingAgentTeam),
        content: const Text(
          'Adds the five GrowERP marketing agents (Outreach Personalizer, '
          'SDR, Lead Triage, Content and Social, Marketing Ops Digest) to '
          'your company. Schedules start disabled except the daily digest. '
          'Safe to run again: existing agents are updated, not duplicated.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelEnableTeam'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmEnableTeam'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkConfigService.create();
      await svc.enableMarketingTeam();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_marketingAgentTeamEnabled,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_enableFailedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAgentDemo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_loadAgentDemo),
        content: const Text(
          'Adds the Agent Control Center demo: an Operations Assistant that '
          'delegates to Sales, Inventory and Support specialists. '
          'Safe to run again: existing agents are updated, not duplicated.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelLoadAgentDemo'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmLoadAgentDemo'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkConfigService.create();
      await svc.loadAgentDemo();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdkLocalizations.of(context)!.adk_agentDemoLoaded),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_loadFailedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _edit(AdkAgentConfig cfg) async {
    final result = await AdkAgentConfigDialog.show(context, existing: cfg);
    if (result != null) await _load();
  }

  Future<void> _delete(AdkAgentConfig cfg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_deleteAgent),
        content: Text(
          AdkLocalizations.of(
            context,
          )!.adk_deleteCfgagentnameThisCannot(cfg.agentName.toString()),
        ),
        actions: [
          TextButton(
            key: const Key('cancelDeleteAgent'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteAgent'),
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
            content: Text(
              AdkLocalizations.of(context)!.adk_deleteFailedE(e.toString()),
            ),
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
          searchHint: AdkLocalizations.of(context)!.adk_searchHintAgents,
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
          actions: [
            IconButton(
              key: const Key('loadAgentDemo'),
              icon: const Icon(Icons.science),
              tooltip: 'Load agent demo',
              onPressed: _loadAgentDemo,
            ),
            IconButton(
              key: const Key('enableMarketingTeam'),
              icon: const Icon(Icons.rocket_launch),
              tooltip: 'Enable marketing agent team',
              onPressed: _enableMarketingTeam,
            ),
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
            Text(
              AdkLocalizations.of(context)!.adk_noAgentsYetNtap,
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
        ? [
            StyledColumn(header: '', flex: 1),
            StyledColumn(
              header: AdkLocalizations.of(context)!.adk_tableHdrInfo,
              flex: 5,
            ),
            StyledColumn(header: '', flex: 2),
          ]
        : [
            StyledColumn(header: '', flex: 1),
            StyledColumn(
              header: AdkLocalizations.of(context)!.adk_tableHdrName,
              flex: 2,
            ),
            StyledColumn(
              header: AdkLocalizations.of(context)!.adk_tableHdrModel,
              flex: 2,
            ),
            StyledColumn(
              header: AdkLocalizations.of(context)!.adk_tableHdrInstruction,
              flex: 4,
            ),
            StyledColumn(
              header: AdkLocalizations.of(context)!.adk_tableHdrSchedule,
              flex: 2,
            ),
            StyledColumn(header: '', flex: 1),
          ];

    final rows = _configs.asMap().entries.map((entry) {
      final i = entry.key;
      final cfg = entry.value;
      final hasSchedule =
          cfg.scheduleEnabled &&
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
            key: Key('editAdkAgent$i'),
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _edit(cfg),
          ),
          IconButton(
            key: Key('deleteAdkAgent$i'),
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
                key: Key('name$i'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                cfg.modelName ?? 'gemini-2.5-flash-lite',
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
        // 'name$i' (same as phone) so doNewSearch can find/open the row on desktop
        Text(cfg.agentName ?? '(unnamed)', key: Key('name$i')),
        Text(
          cfg.modelName ?? 'gemini-2.5-flash-lite',
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
