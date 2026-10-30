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

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'adk_knowledge_service.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

/// The company's agent knowledge base: add notes/documents, or a ZIP of
/// documents loaded in the background, that agents can retrieve via the
/// searchKnowledge tool. Statistics on top. Tenant-scoped by the backend.
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
  AdkKnowledgeStats? _stats;
  AdkKnowledgeImport? _import;
  Timer? _importPoll;
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
    _checkImport();
  }

  @override
  void dispose() {
    _importPoll?.cancel();
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
    _loadStats();
  }

  /// Statistics are extra: a failure leaves the panel out, not the list.
  Future<void> _loadStats() async {
    try {
      final svc = await AdkKnowledgeService.create();
      final stats = await svc.stats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  /// Show the progress of a load still running, also one started before the
  /// user left this screen.
  Future<void> _checkImport() async {
    try {
      final svc = await AdkKnowledgeService.create();
      final job = await svc.importStatus();
      if (mounted && job.isRunning) _follow(job);
    } catch (_) {}
  }

  /// Poll a running load every 2 seconds until it is done.
  void _follow(AdkKnowledgeImport job) {
    setState(() => _import = job);
    _importPoll?.cancel();
    _importPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
      AdkKnowledgeImport now;
      try {
        final svc = await AdkKnowledgeService.create();
        now = await svc.importStatus(job.adkKnowledgeImportId);
      } catch (_) {
        return;
      }
      if (!mounted) return;
      setState(() => _import = now);
      if (now.isRunning) return;
      _importPoll?.cancel();
      _importPoll = null;
      _load();
      _showImportResult(now);
    });
  }

  void _showImportResult(AdkKnowledgeImport job) {
    final l = AdkLocalizations.of(context)!;
    final name = job.jobType == 'REINDEX'
        ? l.adk_kReindex
        : (job.fileName ?? '');
    final failed = job.status == 'ERROR';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('knowledgeImportResult'),
        duration: const Duration(seconds: 8),
        backgroundColor: failed ? Colors.red : null,
        content: Text(
          failed
              ? l.adk_kImportFailed(name, job.errorMessage ?? '')
              : l.adk_kImportDone(
                  name,
                  '${job.createdCount}',
                  '${job.updatedCount}',
                  '${job.skippedCount}',
                ),
        ),
        action: job.skipped.isEmpty
            ? null
            : SnackBarAction(
                label: l.adk_kSkippedFiles,
                onPressed: () => _showSkipped(job.skipped),
              ),
      ),
    );
  }

  void _showSkipped(List<AdkKnowledgeSkipped> skipped) {
    final phone = isAPhone(context);
    showDialog<void>(
      context: context,
      builder: (dctx) => Dialog(
        key: const Key('knowledgeSkippedDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: AdkLocalizations.of(context)!.adk_kSkippedFiles,
          width: phone ? 400 : 600,
          height: phone ? 500 : 450,
          child: ListView(
            children: [
              for (final s in skipped)
                ListTile(
                  dense: true,
                  title: Text(s.path),
                  subtitle: Text(s.reason),
                ),
            ],
          ),
        ),
      ),
    );
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
                child: MarkdownEditor(
                  controller: textCtrl,
                  inputKey: const Key('knowledgeText'),
                  label: 'Content (policy, note, document…)',
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
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick a text document, read it, and open the form pre-filled so the user can
  /// review/edit before ingesting it (sourceType=upload).
  Future<void> _upload() async {
    PlatformFile? f;
    try {
      f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'txt',
          'md',
          'markdown',
          'csv',
          'json',
          'log',
          'text',
          'zip',
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_couldNotOpenFile(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (f.name.toLowerCase().endsWith('.zip')) {
      await _uploadZip(f.name, bytes);
      return;
    }
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = String.fromCharCodes(bytes);
    }
    final dot = f.name.lastIndexOf('.');
    final base = dot > 0 ? f.name.substring(0, dot) : f.name;
    if (!mounted) return;
    final r = await _knowledgeForm(
      heading: 'Add document',
      title: base,
      text: content,
    );
    if (r == null) return;
    setState(() => _loading = true);
    try {
      final svc = await AdkKnowledgeService.create();
      await svc.add(r.title, r.text, sourceType: 'upload');
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load every supported document in a ZIP in the background; the paths in
  /// the ZIP become the titles, so the folder structure stays visible.
  Future<void> _uploadZip(String fileName, List<int> bytes) async {
    final l = AdkLocalizations.of(context)!;
    if (bytes.length > 25 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.adk_kZipTooLarge(fileName)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.adk_kZipConfirmTitle),
        content: Text(l.adk_kZipConfirm(fileName)),
        actions: [
          TextButton(
            key: const Key('cancelZipLoad'),
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmZipLoad'),
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l.adk_kLoad),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _startJob((svc) => svc.importZip(fileName, bytes));
  }

  Future<void> _reindex() => _startJob((svc) => svc.reindex());

  Future<void> _startJob(
    Future<AdkKnowledgeImport> Function(AdkKnowledgeService) start,
  ) async {
    try {
      final svc = await AdkKnowledgeService.create();
      final job = await start(svc);
      if (mounted) _follow(job);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Import the company's product catalog into the knowledge base (one doc per
  /// product, upserted server-side).
  Future<void> _importProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_importProducts),
        content: const Text(
          'Add (or refresh) one knowledge entry per product so agents can answer '
          'questions about your catalog. This may take a moment.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelImport'),
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmImport'),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      final svc = await AdkKnowledgeService.create();
      final n = await svc.importProducts();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_importedNProductS(n.toString()),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
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
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
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
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _delete(AdkKnowledgeDoc d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_delete),
        content: Text(
          AdkLocalizations.of(
            context,
          )!.adk_removeDtitleFromThe(d.title.toString()),
        ),
        actions: [
          TextButton(
            key: const Key('cancelDeleteKnowledge'),
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteKnowledge'),
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
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AdkLocalizations.of(context)!.adk_errorError(_error.toString()),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    // No AppBar — the title comes from the app shell/menu. Title-bar actions live
    // on the search line; add is a FAB. Same design as the user list.
    return Column(
      children: [
        ListFilterBar(
          searchHint: AdkLocalizations.of(context)!.adk_searchHintKnowledge,
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
          actions: [
            IconButton(
              key: const Key('uploadKnowledge'),
              icon: const Icon(Icons.upload_file),
              tooltip: AdkLocalizations.of(context)!.adk_kUploadTooltip,
              onPressed: _import?.isRunning == true ? null : _upload,
            ),
            IconButton(
              key: const Key('importProductsKnowledge'),
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: 'Import product catalog',
              onPressed: _importProducts,
            ),
            IconButton(
              key: const Key('refreshKnowledge'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
          ],
        ),
        if (_import?.isRunning == true) _importProgress(_import!),
        if (_stats != null) _statsPanel(_stats!),
        Expanded(
          child: Stack(
            children: [
              StyledDataTable(
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
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  key: const Key('addKnowledge'),
                  heroTag: 'adkKnowledgeAdd',
                  onPressed: _add,
                  tooltip: 'Add knowledge',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _importProgress(AdkKnowledgeImport job) {
    final l = AdkLocalizations.of(context)!;
    final total = job.fileCount;
    final done = job.processedCount;
    return Padding(
      key: const Key('knowledgeImportProgress'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.jobType == 'REINDEX'
                ? l.adk_kReindexProgress('$done', '$total')
                : l.adk_kImportProgress(job.fileName ?? '', '$done', '$total'),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total > 0 ? done / total : null),
        ],
      ),
    );
  }

  Widget _statsPanel(AdkKnowledgeStats st) {
    final l = AdkLocalizations.of(context)!;
    final theme = Theme.of(context);
    String date(DateTime? d) =>
        d == null ? l.adk_kStatNever : d.toLocalizedDateOnly(context);
    Widget stat(String key, String label, String value) => Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, key: Key(key), style: theme.textTheme.titleMedium),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
    Widget chips(String label, List<String> items) => Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:', style: theme.textTheme.bodySmall),
        for (final i in items)
          Chip(label: Text(i), visualDensity: VisualDensity.compact),
      ],
    );
    final warnings = <String>[
      if (st.currentEmbeddingModel == null && st.docCount > 0)
        l.adk_kHealthNoKey,
      if (st.staleDocCount > 0) l.adk_kHealthStale('${st.staleDocCount}'),
      if (st.emptyDocCount > 0) l.adk_kHealthEmpty('${st.emptyDocCount}'),
    ];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            stat('knowledgeStatDocs', l.adk_kStatDocs, '${st.docCount}'),
            stat('knowledgeStatChunks', l.adk_kStatChunks, '${st.chunkCount}'),
            stat('knowledgeStatTokens', l.adk_kStatTokens, '${st.tokenCount}'),
            stat(
              'knowledgeStatAdded',
              l.adk_kStatAdded30,
              '${st.docsAddedLast30Days}',
            ),
            stat(
              'knowledgeStatLastChange',
              l.adk_kStatLastChange,
              date(st.lastChangedDate),
            ),
            stat(
              'knowledgeStatSearches',
              l.adk_kStatSearches30,
              '${st.searchCountLast30Days}',
            ),
            stat(
              'knowledgeStatNoHits',
              l.adk_kStatNoHits,
              '${st.emptySearchCountLast30Days}',
            ),
            stat(
              'knowledgeStatLastSearch',
              l.adk_kStatLastSearch,
              date(st.lastSearchDate),
            ),
          ],
        ),
        if (st.bySourceType.isNotEmpty) ...[
          const SizedBox(height: 8),
          chips(l.adk_kStatByType, [
            for (final t in st.bySourceType) '${t.sourceType} ${t.docCount}',
          ]),
        ],
        if (st.topFolders.isNotEmpty) ...[
          const SizedBox(height: 4),
          chips(l.adk_kStatFolders, [
            for (final f in st.topFolders) '${f.folder} ${f.docCount}',
          ]),
        ],
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(w)),
              ],
            ),
          ),
        if (st.staleDocCount > 0 && st.currentEmbeddingModel != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('reindexKnowledge'),
              icon: const Icon(Icons.autorenew),
              label: Text(l.adk_kReindex),
              onPressed: _import?.isRunning == true ? null : _reindex,
            ),
          ),
      ],
    );
    // phone: collapsed so the list keeps the screen; open when there is a problem
    return Padding(
      key: const Key('knowledgeStats'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // own Material: the shell's ColoredBox would hide the tile's ink
      child: isAPhone(context)
          ? Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: const Key('knowledgeStatsTile'),
                title: Text(
                  '${l.adk_kStatsTitle}: ${st.docCount} ${l.adk_kStatDocs.toLowerCase()}',
                ),
                leading: warnings.isEmpty
                    ? const Icon(Icons.insights)
                    : Icon(Icons.warning_amber, color: theme.colorScheme.error),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [body],
              ),
            )
          : Padding(padding: const EdgeInsets.all(8), child: body),
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    final localizations = AdkLocalizations.of(context)!;
    if (isAPhone(context)) {
      return [
        StyledColumn(header: '', flex: 1),
        StyledColumn(header: localizations.adk_tableHdrTitle, flex: 5),
        StyledColumn(header: '', flex: 1),
      ];
    }
    return [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: localizations.adk_tableHdrTitle, flex: 4),
      StyledColumn(header: localizations.adk_tableHdrType, flex: 2),
      StyledColumn(header: localizations.adk_tableHdrChunks, flex: 1),
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
        Text(
          '${d.title ?? '?'}\n${d.sourceType ?? 'note'} • ${d.chunkCount ?? 0} chunk(s)',
          key: Key('title$index'),
        ),
        delete,
      ];
    }
    return [
      const CircleAvatar(child: Icon(Icons.menu_book)),
      Text(d.title ?? '?', key: Key('knowledgeTitle$index')),
      Text(d.sourceType ?? 'note'),
      Text('${d.chunkCount ?? 0}'),
      delete,
    ];
  }
}
