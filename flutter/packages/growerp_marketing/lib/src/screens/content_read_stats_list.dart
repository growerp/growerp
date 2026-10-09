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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Website reads per master content piece. Adapted posts link to the website
/// with utm tags; a visit counts as "landed" on arrival and as "read" once the
/// page was visible long enough and scrolled, which bots, link previews and
/// mail privacy proxies never do.
class ContentReadStatsList extends StatefulWidget {
  const ContentReadStatsList({super.key});

  @override
  ContentReadStatsListState createState() => ContentReadStatsListState();
}

class ContentReadStatsListState extends State<ContentReadStatsList> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  List<ContentReadStats> stats = const [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String searchString = '']) async {
    // enterText fires onChanged twice; only the latest request may set state
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RestClient>().getContentReadStats(
            searchString: searchString.isEmpty ? null : searchString,
          );
      if (mounted && requestId == _requestId) {
        setState(() => stats = result.contentReadStats);
      }
    } catch (e) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  String _platforms(ContentReadStats s) => s.platforms
      .map((p) => '${p.platform.isEmpty ? '?' : p.platform} ${p.reads}')
      .join(' · ');

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    final columns = isPhone
        ? [
            StyledColumn(header: 'Content', flex: 4),
            StyledColumn(header: 'Reads', flex: 2),
          ]
        : [
            StyledColumn(header: 'ID', flex: 1),
            StyledColumn(header: 'Title', flex: 3),
            StyledColumn(header: 'Landed', flex: 1),
            StyledColumn(header: 'Reads', flex: 1),
            StyledColumn(header: 'Read %', flex: 1),
            StyledColumn(header: 'Per platform (reads)', flex: 3),
          ];
    final rows = stats.asMap().entries.map((entry) {
      final index = entry.key;
      final s = entry.value;
      if (isPhone) {
        return <Widget>[
          Column(
            key: Key('contentReadInfo$index'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${s.campaign} ${(s.title ?? '').truncate(30)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _platforms(s),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Text('${s.reads}/${s.landings}', key: Key('reads$index')),
        ];
      }
      return <Widget>[
        Text(s.campaign, key: const Key('contentReadItem')),
        Text(
          (s.title ?? '').truncate(40),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('${s.landings}', key: Key('landings$index')),
        Text(
          '${s.reads}',
          key: Key('reads$index'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('${s.readRate}%', key: Key('readRate$index')),
        Text(_platforms(s), maxLines: 1, overflow: TextOverflow.ellipsis),
      ];
    }).toList();

    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search by content id or title',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: _load,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: !_loading && stats.isEmpty && _error == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No website reads yet.\nAdapt a master content piece '
                      'with a Target URL on your website: every platform '
                      'post links there with its own tag and the reads show '
                      'up here.',
                      key: Key('noContentReads'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : StyledDataTable(
                  key: const Key('contentReadStatsList'),
                  columns: columns,
                  rows: rows,
                  isLoading: _loading && stats.isEmpty,
                  scrollController: _scrollController,
                  rowHeight: isPhone ? 64 : 56,
                  onRowTap: (index) => showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) =>
                        ContentReadStatsDialog(stats: stats[index]),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Per-platform breakdown of the website reads of one content piece.
class ContentReadStatsDialog extends StatelessWidget {
  const ContentReadStatsDialog({super.key, required this.stats});
  final ContentReadStats stats;

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    return Dialog(
      key: Key('ContentReadStatsDialog${stats.campaign}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Website reads #${stats.campaign}',
        width: isPhone ? 400 : 600,
        height: isPhone ? 500 : 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((stats.title ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(stats.title!,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              Text(
                'Landed ${stats.landings} (${stats.uniqueVisitors} unique) · '
                'read ${stats.reads} (${stats.readRate}%) · '
                'avg ${stats.avgDwellSeconds}s on page',
                key: const Key('contentReadTotals'),
              ),
              const SizedBox(height: 4),
              Text(
                'Landed counts every visit from a tagged link, link previews '
                'and scanners included; read only counts visitors who stayed '
                'and scrolled.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              GroupingDecorator(
                labelText: 'Per platform',
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(2)},
                  children: [
                    const TableRow(children: [
                      Text('Platform',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Landed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Reads',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Avg s',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    ...stats.platforms.map((p) => TableRow(
                          key: ValueKey('platform${p.platform}'),
                          children: [
                            Text(p.platform.isEmpty ? '?' : p.platform),
                            Text('${p.landings}'),
                            Text('${p.reads}'),
                            Text('${p.avgDwellSeconds}'),
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
