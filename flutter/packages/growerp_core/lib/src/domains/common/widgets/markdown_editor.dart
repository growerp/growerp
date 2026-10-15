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
import 'package:flutter/rendering.dart';
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
/// [inputKey] is put on the Source text field, in Visual mode on the visual
/// editor (integration tests: CommonTest.enterText switches to Source).
/// Without [height] the editor fills its parent, which must be bounded.
/// With [validator] the editor takes part in the surrounding [Form].
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final Key? inputKey;
  final String? label;
  final double? height;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final String? helper;
  final bool enabled;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.inputKey,
    this.label,
    this.height,
    this.validator,
    this.hint,
    this.helper,
    this.enabled = true,
  });

  /// [markdown] as one line of plain text, for list cells and chips.
  static String toPlainText(String markdown) => _html(markdown)
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

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
  // the markdown the visual editor last wrote into the controller
  String? _written;

  @override
  void initState() {
    super.initState();
    _visualSafe = MarkdownEditor.roundTrips(widget.controller.text);
    _source = !_visualSafe;
    if (!_source) _loadVisual();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _onControllerChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _disposeVisual();
    super.dispose();
  }

  /// text set from outside (data loaded, AI generated): show it
  void _onControllerChanged() {
    if (_source || widget.controller.text == _written) return;
    setState(() {
      _visualSafe = MarkdownEditor.roundTrips(widget.controller.text);
      _source = !_visualSafe;
      if (_source) {
        _disposeVisual();
      } else {
        _loadVisual();
      }
    });
  }

  void _loadVisual() {
    _disposeVisual();
    _written = widget.controller.text;
    final delta = MarkdownEditor._mdToDelta.convert(widget.controller.text);
    final quill = QuillController(
      document: delta.isEmpty ? Document() : Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: !widget.enabled,
    );
    _changes = quill.document.changes.listen((_) {
      _written = MarkdownEditor._toMarkdown(quill.document.toDelta());
      widget.controller.text = _written!;
    });
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
            enabled: widget.enabled,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Markdown',
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
            // the key in both modes so tests can find (scroll to) the editor
            child: Container(
              key: widget.inputKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                children: [
                  if (widget.enabled) ...[
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
                  ],
                  Expanded(
                    child: QuillEditor.basic(
                      key: const Key('markdownVisualEditor'),
                      controller: _quill!,
                      config: QuillEditorConfig(
                        padding: const EdgeInsets.all(10),
                        placeholder: widget.hint,
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
    final sized = _IntrinsicSafe(
      height: widget.height,
      child: widget.height == null
          ? editor
          : SizedBox(height: widget.height, child: editor),
    );
    if (widget.validator == null && widget.helper == null) return sized;
    Widget withNote(String? error) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.height == null ? Expanded(child: sized) : sized,
        if (error != null || widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              error ?? widget.helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    if (widget.validator == null) return withNote(null);
    return FormField<String>(
      validator: (_) => widget.validator!(widget.controller.text),
      builder: (field) => withNote(field.errorText),
    );
  }
}

/// The visual editor scrolls, and a scroll view cannot report intrinsic
/// sizes, which an AlertDialog asks for: answer with fixed ones instead.
class _IntrinsicSafe extends SingleChildRenderObjectWidget {
  final double? height;

  const _IntrinsicSafe({required this.height, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicSafe(height ?? 0);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIntrinsicSafe renderObject,
  ) => renderObject.height = height ?? 0;
}

class _RenderIntrinsicSafe extends RenderProxyBox {
  double height;

  _RenderIntrinsicSafe(this.height);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 400;

  @override
  double computeMinIntrinsicHeight(double width) => height;

  @override
  double computeMaxIntrinsicHeight(double width) => height;
}
