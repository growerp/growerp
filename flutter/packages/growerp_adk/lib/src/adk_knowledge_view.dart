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
import 'adk_knowledge_service.dart';

/// The company's agent knowledge base: add notes/documents that agents can
/// retrieve via the searchKnowledge tool. Tenant-scoped by the backend.
class AdkKnowledgeView extends StatefulWidget {
  const AdkKnowledgeView({super.key});

  @override
  State<AdkKnowledgeView> createState() => _AdkKnowledgeViewState();
}

class _AdkKnowledgeViewState extends State<AdkKnowledgeView> {
  List<AdkKnowledgeDoc> _docs = [];
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
      final svc = await AdkKnowledgeService.create();
      final list = await svc.list();
      if (mounted) setState(() => _docs = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Add knowledge'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('knowledgeTitle'),
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('knowledgeText'),
                controller: textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Text (policy, note, document…)',
                ),
                maxLines: 8,
                minLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('knowledgeSave'),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (titleCtrl.text.trim().isEmpty || textCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final svc = await AdkKnowledgeService.create();
      await svc.add(titleCtrl.text.trim(), textCtrl.text.trim());
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _docs.isEmpty
                  ? const Center(
                      child: Text(
                          'No knowledge yet.\nTap + to add a policy or note.',
                          textAlign: TextAlign.center))
                  : ListView.builder(
                      itemCount: _docs.length,
                      itemBuilder: (context, index) {
                        final d = _docs[index];
                        return Card(
                          key: Key('knowledge$index'),
                          child: ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(d.title ?? '?'),
                            subtitle: Text(
                                '${d.sourceType ?? 'note'} • ${d.chunkCount ?? 0} chunk(s)'),
                            trailing: IconButton(
                              key: Key('deleteKnowledge$index'),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(d),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
