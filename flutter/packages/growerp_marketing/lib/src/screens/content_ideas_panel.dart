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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

const List<String> contentIdeaPnpTypes = ['OTHER', 'PAIN', 'NEWS', 'PRIZE'];

/// Ideas strip at the top of the Content screen: raw text, notes or an article
/// URL waiting to become a ~500 word website article. Tap one to edit it or to
/// write the article (the idea is deleted then); long-press and drag to change
/// the order the weekly agent uses them in (left first). [onArticleWritten]
/// lets the content list show the new piece.
class ContentIdeasPanel extends StatefulWidget {
  const ContentIdeasPanel({super.key, this.onArticleWritten});
  final VoidCallback? onArticleWritten;

  @override
  ContentIdeasPanelState createState() => ContentIdeasPanelState();
}

class ContentIdeasPanelState extends State<ContentIdeasPanel> {
  List<ContentIdea> ideas = const [];
  // kept for the session, so the strip stays collapsed when the screen reopens
  static bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<RestClient>().getContentIdeas();
      if (mounted) setState(() => ideas = result.contentIdeas);
    } catch (_) {
      // the strip is optional: the content list still works without it
    }
  }

  Future<void> _open(ContentIdea? idea) async {
    final changed = await showDialog<bool>(
      barrierDismissible: true,
      context: context,
      builder: (_) => RepositoryProvider.value(
        value: context.read<RestClient>(),
        child: ContentIdeaDialog(idea: idea),
      ),
    );
    if (changed == true) {
      final before = ideas.length;
      await _load();
      // an idea that disappeared was written into an article (or deleted)
      if (ideas.length < before) widget.onArticleWritten?.call();
    }
  }

  // newIndex is already adjusted for the removed item (onReorderItem)
  Future<void> _reorder(int oldIndex, int newIndex) async {
    final previous = ideas;
    final reordered = List<ContentIdea>.from(ideas);
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    setState(() => ideas = reordered);
    try {
      await context.read<RestClient>().reorderContentIdeas(
          ideaIds: reordered.map((i) => i.ideaId!).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => ideas = previous);
      HelperFunctions.showMessage(context, 'Reorder failed: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('contentIdeasPanel'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          InkWell(
            key: const Key('ideasToggle'),
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Row(
              children: [
                Icon(_collapsed ? Icons.chevron_right : Icons.expand_more,
                    size: 20, color: colors.onSurface),
                Text('Ideas (${ideas.length})',
                    key: const Key('ideasCount'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: colors.onSurface)),
              ],
            ),
          ),
          if (!_collapsed) ...[
          const SizedBox(width: 8),
          ActionChip(
            key: const Key('addNewContentIdea'),
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add idea'),
            tooltip:
                'Text, notes or an article URL to turn into a website article',
            onPressed: () => _open(null),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ReorderableListView.builder(
              key: const Key('contentIdeaChips'),
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: ideas.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(idea.ideaId),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: ActionChip(
                        key: Key('idea$index'),
                        avatar: Icon(
                            (idea.sourceUrl ?? '').isNotEmpty
                                ? Icons.link
                                : Icons.lightbulb_outline,
                            size: 18),
                        label: Text(
                          ((idea.title?.isNotEmpty ?? false)
                                  ? idea.title!
                                  : (idea.rawText ?? idea.sourceUrl ?? ''))
                              .truncate(30),
                          key: Key('ideaTitle$index'),
                        ),
                        tooltip: 'Tap to edit or write; long-press and drag '
                            'to reorder',
                        onPressed: () => _open(idea),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ],
        ],
      ),
    );
  }
}

/// Add or edit one idea and turn it into an article. Pops `true` when
/// anything was saved, so the list reloads.
class ContentIdeaDialog extends StatefulWidget {
  const ContentIdeaDialog({super.key, this.idea});
  final ContentIdea? idea;

  @override
  State<ContentIdeaDialog> createState() => _ContentIdeaDialogState();
}

class _ContentIdeaDialogState extends State<ContentIdeaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _urlController;
  String _pnpType = 'OTHER';
  bool _busy = false;
  // the idea as saved in this dialog: a failed "Write article" keeps the dialog
  // open, and a retry must update that idea instead of creating another one
  String? _ideaId;
  bool _saved = false;
  String? _busyText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea?.title ?? '');
    _textController = TextEditingController(text: widget.idea?.rawText ?? '');
    _urlController = TextEditingController(text: widget.idea?.sourceUrl ?? '');
    _ideaId = widget.idea?.ideaId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  /// Saves the form; returns the saved idea or null on error.
  Future<ContentIdea?> _save() async {
    final client = context.read<RestClient>();
    _saved = true;
    if (_ideaId == null) {
      final created = await client.createContentIdea(
        title: _titleController.text,
        rawText: _textController.text,
        sourceUrl: _urlController.text,
      );
      _ideaId = created.ideaId;
      return created;
    }
    return client.updateContentIdea(
      ideaId: _ideaId!,
      title: _titleController.text,
      rawText: _textController.text,
      sourceUrl: _urlController.text,
    );
  }

  Future<void> _run(String busyText, Future<String?> Function() action) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _busyText = busyText;
    });
    try {
      final message = await action();
      if (!mounted) return;
      if (message != null) {
        HelperFunctions.showMessage(context, message, Colors.green);
      }
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    } catch (e) {
      if (mounted) HelperFunctions.showMessage(context, '$e', Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    final idea = widget.idea;
    return Dialog(
      key: Key('ContentIdeaDialog${idea?.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Idea #${idea?.pseudoId ?? 'New'}',
        width: isPhone ? 400 : 700,
        height: isPhone ? 700 : 680,
        child: _busy
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoadingIndicator(),
                    const SizedBox(height: 16),
                    Text(_busyText ?? ''),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  key: const Key('contentIdeaDialogListView'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paste an article, notes or a one-line idea, give the '
                        'URL of an article, or both: both are used. "Write '
                        'article" turns it into a ~500 word article in your '
                        'house style; it goes on your website when you approve '
                        'it under Content.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('ideaTitle'),
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title or one-line idea (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('ideaRawText'),
                        controller: _textController,
                        minLines: 6,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          labelText: 'Text, notes or article',
                          alignLabelWithHint: true,
                        ),
                        validator: (_) => _textController.text.trim().isEmpty &&
                                _urlController.text.trim().isEmpty &&
                                _titleController.text.trim().isEmpty
                            ? 'Give an idea, some text, an article URL, or both'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('ideaSourceUrl'),
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Article URL (optional)',
                          hintText: 'https://...',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty ||
                                RegExp(r'^https?://', caseSensitive: false)
                                    .hasMatch(value!.trim())
                            ? null
                            : 'Must start with http:// or https://',
                      ),
                      ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          key: const Key('ideaPnpType'),
                          initialValue: _pnpType,
                          decoration: const InputDecoration(
                              labelText: 'Angle (Pain-News-Prize)'),
                          items: contentIdeaPnpTypes
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => _pnpType = v ?? 'OTHER',
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('cancel'),
                              // reload the list when something was saved before an error
                              onPressed: () => Navigator.of(context).pop(_saved),
                              child: const Text('Cancel'),
                            ),
                          ),
                          ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('ideaSave'),
                                onPressed: () => _run('Saving...', () async {
                                  await _save();
                                  return null;
                                }),
                                child: Text(
                                    idea?.ideaId == null ? 'Create' : 'Update'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                key: const Key('ideaWriteArticle'),
                                onPressed: () => _run(
                                    'Writing the article, this takes up to a minute...',
                                    () async {
                                  final client = context.read<RestClient>();
                                  final saved = await _save();
                                  if (saved?.ideaId == null) return null;
                                  final article =
                                      await client.writeArticleFromIdea(
                                        ideaId: saved!.ideaId!,
                                        pnpType: _pnpType,
                                      );
                                  return "Article '${article.title}' written: "
                                      'approve it under Content to put it on '
                                      'your website';
                                }),
                                child: const Text('Write article'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (idea?.ideaId != null) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          key: const Key('ideaDiscard'),
                          onPressed: () => _run('Saving...', () async {
                            await context
                                .read<RestClient>()
                                .deleteContentIdea(ideaId: idea!.ideaId!);
                            return null;
                          }),
                          child: const Text('Delete this idea'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
