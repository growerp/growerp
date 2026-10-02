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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'adk_agent_config_dialog.dart';
import 'adk_config_service.dart';

/// Support App View: maintain the shared "_NA_" agent catalog — the generally
/// available agents every tenant can load from its Agent catalog and that
/// the public website lists. Edit (incl. published + category), delete, and
/// upload a team JSON file into the catalog as drafts.
class AdkCatalogMaintainView extends StatefulWidget {
  const AdkCatalogMaintainView({super.key});

  @override
  State<AdkCatalogMaintainView> createState() => _AdkCatalogMaintainViewState();
}

class _AdkCatalogMaintainViewState extends State<AdkCatalogMaintainView> {
  List<AdkAgentConfig> _agents = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final list = await svc.list(catalog: true);
      list.sort((a, b) => '${a.catalogCategory ?? ''} ${a.agentName ?? ''}'
          .compareTo('${b.catalogCategory ?? ''} ${b.agentName ?? ''}'));
      if (mounted) setState(() => _agents = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Search matches name, team or category, client side.
  List<AdkAgentConfig> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _agents;
    return _agents
        .where((a) => [a.agentName, a.teamName, a.catalogCategory]
            .any((v) => (v ?? '').toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _edit(AdkAgentConfig a) async {
    await AdkAgentConfigDialog.show(context, existing: a, catalog: true);
    await _load();
  }

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(
      allowedExtensions: ['json'],
      type: FileType.custom,
    );
    if (file == null) return;
    final jsonText = utf8.decode(await file.readAsBytes());
    try {
      final svc = await AdkConfigService.create();
      final result = await svc.importTeam(jsonText, toCatalog: true);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added "${result.importedTeamName}" to the catalog '
              '(${result.importedAgentCount} agents, unpublished)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search name, team or category',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) => setState(() => _search = value),
          actions: [
            IconButton(
              key: const Key('refreshCatalogMaintain'),
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
                  key: const Key('uploadCatalogTeam'),
                  heroTag: 'catalogTeamUpload',
                  onPressed: _upload,
                  tooltip: 'Upload team to catalog',
                  child: const Icon(Icons.upload),
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
    final agents = _filtered;
    if (agents.isEmpty) {
      return const Center(child: Text('No catalog agents found.'));
    }
    final phone = isAPhone(context);
    final columns = phone
        ? [
            StyledColumn(header: 'Agent', flex: 5),
            StyledColumn(header: 'Live', flex: 1),
          ]
        : [
            StyledColumn(header: 'Name', flex: 3),
            StyledColumn(header: 'Team', flex: 3),
            StyledColumn(header: 'Category', flex: 2),
            StyledColumn(header: 'Description', flex: 5),
            StyledColumn(header: 'Published', flex: 1),
          ];
    final rows = agents.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      final published = Icon(
        a.catalogPublished ? Icons.check_circle : Icons.edit_note,
        key: Key('catalogPublished$i'),
        color: a.catalogPublished ? Colors.green : Colors.grey,
      );
      if (phone) {
        return <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(a.agentName ?? '', key: Key('catalogName$i')),
              Text(
                '${a.catalogCategory ?? '-'} · ${a.teamName ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          published,
        ];
      }
      return <Widget>[
        Text(a.agentName ?? '', key: Key('catalogName$i')),
        Text(a.teamName ?? ''),
        Text(a.catalogCategory ?? '', key: Key('catalogCategory$i')),
        Text(a.description ?? '', overflow: TextOverflow.ellipsis, maxLines: 2),
        published,
      ];
    }).toList();
    return StyledDataTable(
      key: const Key('catalogMaintainList'),
      columns: columns,
      rows: rows,
      rowHeight: phone ? 64 : 56,
      onRowTap: (index) => _edit(agents[index]),
    );
  }
}
