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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'wiki_page_dialog.dart';

/// Browse and edit the pages of a wiki space (default: the GROWERP_OKF
/// knowledge bundle produced by the OKF exporter). Generated pages live under
/// tables/ and datasets/; hand-authored pages (e.g. notes/) survive re-export.
class WikiList extends StatefulWidget {
  const WikiList({super.key});

  @override
  WikiListState createState() => WikiListState();
}

class WikiListState extends State<WikiList> {
  List<WikiSpace> spaces = const [];
  List<WikiPage> pages = const [];
  String wikiSpaceId = 'GROWERP_OKF';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = context.read<RestClient>();
      if (spaces.isEmpty) {
        final spacesResult = await client.getWikiSpaces(limit: 100);
        spaces = spacesResult.wikiSpaces;
        if (spaces.isNotEmpty &&
            !spaces.any((s) => s.wikiSpaceId == wikiSpaceId)) {
          wikiSpaceId = spaces.first.wikiSpaceId ?? '';
        }
      }
      final result = await client.getWikiPages(
        wikiSpaceId: wikiSpaceId,
        searchString: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        limit: 100,
      );
      if (mounted) setState(() => pages = result.wikiPages);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPage(WikiPage page) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WikiPageDialog(
        wikiSpaceId: wikiSpaceId,
        pagePath: page.pagePath,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _addPage() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => WikiPageDialog(wikiSpaceId: wikiSpaceId),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && pages.isEmpty && spaces.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  DropdownButton<String>(
                    key: const Key('wikiSpaceDropDown'),
                    value: spaces.any((s) => s.wikiSpaceId == wikiSpaceId)
                        ? wikiSpaceId
                        : null,
                    hint: const Text('Wiki space'),
                    items: spaces
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.wikiSpaceId,
                            child: Text(s.wikiSpaceId ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => wikiSpaceId = value);
                      _load();
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('searchField'),
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search page path',
                        suffixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pages.isEmpty
                  ? const Center(child: Text('No pages found'))
                  : ListView.builder(
                      key: const Key('wikiPageList'),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        final generated =
                            (page.pagePath ?? '').startsWith('tables/') ||
                            (page.pagePath ?? '').startsWith('datasets/') ||
                            page.pagePath == 'index' ||
                            page.pagePath == 'log';
                        // own Material: the app shell paints a ColoredBox
                        // above the nearest Material, hiding tile ink
                        return Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            key: Key('wikiItem$index'),
                            leading: Icon(
                              generated ? Icons.smart_toy : Icons.edit_note,
                              color: generated ? Colors.blueGrey : Colors.green,
                            ),
                            title: Text(page.pagePath ?? '(root)'),
                            subtitle: Text(
                              generated
                                  ? 'generated (overwritten on export)'
                                  : 'authored',
                            ),
                            onTap: () => _openPage(page),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 50,
          child: FloatingActionButton(
            key: const Key('addNew'),
            onPressed: _addPage,
            tooltip: 'Add page',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
