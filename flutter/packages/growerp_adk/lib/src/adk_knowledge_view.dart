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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'adk_knowledge_service.dart';

/// The company's agent knowledge base: add notes/documents that agents can
/// retrieve via the searchKnowledge tool. Tenant-scoped by the backend.
class AdkKnowledgeView extends StatefulWidget {
  const AdkKnowledgeView({super.key});

  @override
  State<AdkKnowledgeView> createState() => _AdkKnowledgeViewState();
}

class _AdkKnowledgeViewState extends State<AdkKnowledgeView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  List<AdkKnowledgeDoc> _docs = [];
  bool _loading = true;
  String? _error;
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
      final svc = await AdkKnowledgeService.create();
      final list = await svc.list(search: _search.isEmpty ? null : _search);
      if (mounted) setState(() => _docs = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Shared title+content form, using the standard GrowERP detail-dialog frame
  /// (Dialog + popUp), the same design as the user detail screen. Returns the
  /// entered (title, text) on save, or null on cancel.
  Future<({String title, String text})?> _knowledgeForm({
    required String heading,
    String title = '',
    String text = '',
  }) {
    final titleCtrl = TextEditingController(text: title);
    final textCtrl = TextEditingController(text: text);
    final phone = isAPhone(context);
    return showDialog<({String title, String text})>(
      context: context,
      builder: (dctx) => Dialog(
        key: const Key('AdkKnowledgeDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: heading,
          width: phone ? 400 : 800,
          height: phone ? 600 : 550,
          child: Column(
            children: [
              TextFormField(
                key: const Key('knowledgeTitle'),
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextFormField(
                  key: const Key('knowledgeText'),
                  controller: textCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Content (policy, note, document…)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  expands: true,
                  maxLines: null,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const Key('knowledgeSave'),
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty ||
                          textCtrl.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(dctx, (
                        title: titleCtrl.text.trim(),
                        text: textCtrl.text.trim(),
                      ));
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add() async {
    final r = await _knowledgeForm(heading: 'Add knowledge');
    if (r == null) return;
    setState(() => _loading = true);
    try {
      final svc = await AdkKnowledgeService.create();
      await svc.add(r.title, r.text);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Open a doc: fetch its full text, let the user edit title/content and Save
  /// (re-chunks + re-embeds server-side).
  Future<void> _openDoc(AdkKnowledgeDoc d) async {
    final svc = await AdkKnowledgeService.create();
    AdkKnowledgeDoc full;
    try {
      full = await svc.detail(d.adkKnowledgeDocId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!mounted) return;
    final r = await _knowledgeForm(
      heading: 'Edit knowledge',
      title: full.title ?? '',
      text: full.content ?? '',
    );
    if (r == null) return;
    setState(() => _loading = true);
    try {
      await svc.update(d.adkKnowledgeDocId!, title: r.title, text: r.text);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(AdkKnowledgeDoc d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "${d.title}" from the knowledge base?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkKnowledgeService.create();
      await svc.delete(d.adkKnowledgeDocId!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge base'),
        actions: [
          IconButton(
            key: const Key('refreshKnowledge'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addKnowledge'),
        onPressed: _add,
        tooltip: 'Add knowledge',
        child: const Icon(Icons.add),
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar — same component/behaviour as the user list.
                ListFilterBar(
                  searchHint: 'Search knowledge...',
                  searchController: _searchController,
                  focusNode: _searchFocusNode,
                  onSearchChanged: (value) {
                    _search = value;
                    _load();
                  },
                ),
                Expanded(
                  child: StyledDataTable(
                    columns: _columns(context),
                    rows: _docs.map(_rowFor).toList(),
                    isLoading: _loading && _docs.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isAPhone(context) ? 72 : 56,
                    onRowTap: (index) async {
                      await _openDoc(_docs[index]);
                      _searchFocusNode.requestFocus();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    if (isAPhone(context)) {
      return const [
        StyledColumn(header: '', flex: 1),
        StyledColumn(header: 'Title', flex: 5),
        StyledColumn(header: '', flex: 1),
      ];
    }
    return const [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: 'Title', flex: 4),
      StyledColumn(header: 'Type', flex: 2),
      StyledColumn(header: 'Chunks', flex: 1),
      StyledColumn(header: '', flex: 1),
    ];
  }

  List<Widget> _rowFor(AdkKnowledgeDoc d) {
    final index = _docs.indexOf(d);
    final delete = IconButton(
      key: Key('deleteKnowledge$index'),
      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Delete',
      onPressed: () => _delete(d),
    );
    if (isAPhone(context)) {
      return [
        const CircleAvatar(child: Icon(Icons.menu_book)),
        Text('${d.title ?? '?'}\n${d.sourceType ?? 'note'} • ${d.chunkCount ?? 0} chunk(s)'),
        delete,
      ];
    }
    return [
      const CircleAvatar(child: Icon(Icons.menu_book)),
      Text(d.title ?? '?'),
      Text(d.sourceType ?? 'note'),
      Text('${d.chunkCount ?? 0}'),
      delete,
    ];
  }
}
