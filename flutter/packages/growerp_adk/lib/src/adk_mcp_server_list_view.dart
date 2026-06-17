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
import 'adk_mcp_server_dialog.dart';
import 'adk_config_service.dart';

/// Screen that lists the tenant's external MCP servers and lets users
/// create / edit / delete them. Attach them to agents from the agent dialog.
class AdkMcpServerListView extends StatefulWidget {
  const AdkMcpServerListView({super.key});

  @override
  State<AdkMcpServerListView> createState() => _AdkMcpServerListViewState();
}

class _AdkMcpServerListViewState extends State<AdkMcpServerListView> {
  List<AdkMcpServer> _servers = [];
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
      final list =
          await svc.listMcpServers(search: _search.isEmpty ? null : _search);
      if (mounted) setState(() => _servers = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await AdkMcpServerDialog.show(context);
    if (result != null) await _load();
  }

  Future<void> _edit(AdkMcpServer server) async {
    final result = await AdkMcpServerDialog.show(context, existing: server);
    if (result != null) await _load();
  }

  Future<void> _delete(AdkMcpServer server) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete MCP server?'),
        content: Text(
            'Delete "${server.serverName}"? It will be detached from all agents.'),
        actions: [
          TextButton(
            key: const Key('cancelDeleteServer'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteServer'),
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
      await svc.deleteMcpServer(server.adkMcpServerId!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search MCP servers...',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
          actions: [
            IconButton(
              key: const Key('refreshAdkMcpServers'),
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
                  key: const Key('addAdkMcpServer'),
                  heroTag: 'adkMcpServerAdd',
                  onPressed: _create,
                  tooltip: 'New MCP server',
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
    if (_servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dns_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No MCP servers yet.\nTap + to register one.',
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
            StyledColumn(header: 'Name', flex: 3),
            StyledColumn(header: 'URL', flex: 5),
            StyledColumn(header: 'Transport', flex: 2),
            StyledColumn(header: '', flex: 1),
          ];

    final rows = _servers.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;

      final avatar = CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        child: Icon(
          s.enabled ? Icons.dns : Icons.dns_outlined,
          color: cs.onSecondaryContainer,
        ),
      );

      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('editAdkMcpServer$i'),
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _edit(s),
          ),
          IconButton(
            key: Key('deleteAdkMcpServer$i'),
            icon: Icon(Icons.delete, size: 20, color: cs.error),
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _delete(s),
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
                s.serverName ?? '(unnamed)',
                key: Key('name$i'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                s.url ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              Text(
                s.transport ?? 'sse',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          actions,
        ];
      }

      return [
        avatar,
        Text(s.serverName ?? '(unnamed)', key: Key('name$i')),
        Text(
          s.url ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        Text(
          s.transport ?? 'sse',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        actions,
      ];
    }).toList();

    return StyledDataTable(
      columns: columns,
      rows: rows,
      scrollController: _scrollController,
      rowHeight: phone ? 80 : 56,
      onRowTap: (index) => _edit(_servers[index]),
    );
  }
}
