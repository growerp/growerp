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
import 'package:markdown_widget/markdown_widget.dart';

/// View / edit one wiki page: markdown preview with an edit mode.
/// Pass [pagePath] null for a new page (path becomes editable).
/// Pops with `true` when the page was saved.
class WikiPageDialog extends StatefulWidget {
  final String wikiSpaceId;
  final String? pagePath;

  const WikiPageDialog({super.key, required this.wikiSpaceId, this.pagePath});

  @override
  WikiPageDialogState createState() => WikiPageDialogState();
}

class WikiPageDialogState extends State<WikiPageDialog> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  bool get _isNew => widget.pagePath == null;
  bool _editing = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pathController.text = widget.pagePath ?? '';
    _editing = _isNew;
    if (_isNew) {
      _loading = false;
    } else {
      _loadPage();
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    try {
      final page = await context.read<RestClient>().getWikiPage(
        wikiSpaceId: widget.wikiSpaceId,
        pagePath: widget.pagePath,
      );
      if (mounted) setState(() => _textController.text = page.pageText ?? '');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      HelperFunctions.showMessage(context, 'Page path required', Colors.red);
      return;
    }
    try {
      await context.read<RestClient>().updateWikiPage(
        wikiSpaceId: widget.wikiSpaceId,
        pagePath: path,
        pageText: _textController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'Save failed: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    return Dialog(
      key: const Key('WikiPageDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: _isNew
            ? 'New Wiki Page (${widget.wikiSpaceId})'
            : '${widget.wikiSpaceId}/${widget.pagePath}',
        width: isPhone ? 400 : 900,
        height: 650,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : _dialogContent(),
      ),
    );
  }

  Widget _dialogContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _isNew
                  ? TextFormField(
                      key: const Key('pagePath'),
                      controller: _pathController,
                      decoration: const InputDecoration(
                        labelText:
                            "Page path (e.g. 'notes/my-page' - avoid the "
                            "generated tables/ and datasets/ prefixes)",
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            TextButton.icon(
              key: const Key('editToggle'),
              icon: Icon(_editing ? Icons.preview : Icons.edit),
              label: Text(_editing ? 'Preview' : 'Edit'),
              onPressed: () => setState(() => _editing = !_editing),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _editing
              ? TextFormField(
                  key: const Key('pageText'),
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Markdown text (YAML frontmatter allowed)',
                  ),
                )
              : MarkdownWidget(
                  key: const Key('pagePreview'),
                  data: _textController.text,
                ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              key: const Key('update'),
              onPressed: _save,
              child: Text(_isNew ? 'Create' : 'Update'),
            ),
          ],
        ),
      ],
    );
  }
}
