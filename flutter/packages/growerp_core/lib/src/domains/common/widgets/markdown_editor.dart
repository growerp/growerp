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

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// WYSIWYG markdown editor: a rich-text (Visual) view with a formatting
/// toolbar and a raw markdown (Source) view. [controller] always holds the
/// markdown, so callers read and save it as before.
///
/// Text with formatting the visual editor cannot keep (raw html, tables..)
/// opens in Source mode so nothing is lost silently.
/// [inputKey] is put on the Source text field (used by integration tests,
/// tap Key('markdownModeSource') first).
/// Without [height] the editor fills its parent, which must be bounded.
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final Key? inputKey;
  final String? label;
  final double? height;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.inputKey,
    this.label,
    this.height,
  });

  /// true when [markdown] survives a markdown -> rich text -> markdown trip
  /// unchanged in meaning (compared as rendered html).
  static bool roundTrips(String markdown) {
    final again = _toMarkdown(_mdToDelta.convert(markdown));
    return _html(markdown) == _html(again);
  }

  static String _toMarkdown(Delta delta) {
    if (delta.isEmpty) return '';
    // without a blank line a paragraph after a quote joins the quote
    return _deltaToMd
        .convert(delta)
        .replaceAllMapped(
          RegExp(r'^(>.*)\n(?=[^>\n])', multiLine: true),
          (m) => '${m[1]}\n\n',
        );
  }

  /// escape only what changes the meaning of the text, the default
  /// escapes all punctuation ('Hello\.')
  static void _escape(QuillText text, StringSink out) {
    var content = text.value;
    final isCode =
        text.style.containsKey(Attribute.codeBlock.key) ||
        text.style.containsKey(Attribute.inlineCode.key) ||
        (text.parent?.style.containsKey(Attribute.codeBlock.key) ?? false);
    if (!isCode) {
      content = content.replaceAllMapped(
        RegExp(r'[\\`*_\[\]<]'),
        (m) => '\\${m[0]}',
      );
      // line start: '# ', '> ', '- ', '+ ', '1. ' start a block
      if (text.previous == null) {
        content = content.replaceFirstMapped(
          RegExp(r'^(\s*)([#>+-]|\d+(?=[.)]))'),
          (m) => m[2]!.contains(RegExp(r'\d'))
              ? '${m[1]}${m[2]}\\'
              : '${m[1]}\\${m[2]}',
        );
      }
    }
    out.write(content);
  }

  static String _html(String markdown) => md
      .markdownToHtml(markdown, extensionSet: md.ExtensionSet.gitHubFlavored)
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('> <', '><')
      .trim();

  static final _mdToDelta = MarkdownToDelta(
    markdownDocument: md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ),
  );
  static final _deltaToMd = DeltaToMarkdown(customContentHandler: _escape);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late bool _source;
  late bool _visualSafe;
  QuillController? _quill;
  StreamSubscription? _changes;

  @override
  void initState() {
    super.initState();
    _visualSafe = MarkdownEditor.roundTrips(widget.controller.text);
    _source = !_visualSafe;
    if (!_source) _loadVisual();
  }

  @override
  void dispose() {
    _disposeVisual();
    super.dispose();
  }

  void _loadVisual() {
    _disposeVisual();
    final delta = MarkdownEditor._mdToDelta.convert(widget.controller.text);
    final quill = QuillController(
      document: delta.isEmpty ? Document() : Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _changes = quill.document.changes.listen(
      (_) => widget.controller.text = MarkdownEditor._toMarkdown(
        quill.document.toDelta(),
      ),
    );
    _quill = quill;
  }

  void _disposeVisual() {
    _changes?.cancel();
    _changes = null;
    _quill?.dispose();
    _quill = null;
  }

  void _setSource(bool source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      if (source) {
        _disposeVisual();
      } else {
        _visualSafe = MarkdownEditor.roundTrips(widget.controller.text);
        _loadVisual();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = Row(
      children: [
        if (widget.label != null)
          Text(widget.label!, style: theme.textTheme.titleSmall),
        if (_source && !_visualSafe)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Contains formatting the visual editor cannot keep',
                key: const Key('markdownSourceOnlyHint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        else
          const Spacer(),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Visual', key: Key('markdownModeVisual')),
            ),
            ButtonSegment(
              value: true,
              label: Text('Source', key: Key('markdownModeSource')),
            ),
          ],
          selected: {_source},
          onSelectionChanged: (selected) => _setSource(selected.first),
        ),
      ],
    );

    final Widget body = _source
        ? TextFormField(
            key: widget.inputKey,
            controller: widget.controller,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Markdown',
              alignLabelWithHint: true,
            ),
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            textInputAction: TextInputAction.newline,
          )
        : Localizations.override(
            context: context,
            delegates: const [FlutterQuillLocalizations.delegate],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  QuillSimpleToolbar(
                    controller: _quill!,
                    config: const QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                      showFontFamily: false,
                      showFontSize: false,
                      showUnderLineButton: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showListCheck: false,
                      showIndent: false,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: QuillEditor.basic(
                      key: const Key('markdownVisualEditor'),
                      controller: _quill!,
                      config: QuillEditorConfig(
                        padding: const EdgeInsets.all(10),
                        // markdown paragraphs are blocks: show the gap
                        customStyles: DefaultStyles(
                          paragraph: DefaultStyles.getInstance(context)
                              .paragraph!
                              .copyWith(
                                verticalSpacing: const VerticalSpacing(0, 10),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    final editor = Column(
      children: [
        header,
        const SizedBox(height: 6),
        Expanded(child: body),
      ],
    );
    return widget.height == null
        ? editor
        : SizedBox(height: widget.height, child: editor);
  }
}
