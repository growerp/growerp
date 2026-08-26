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

class AutocompleteLabel<T extends Object> extends StatefulWidget {
  final String label;
  final String? hintText;
  final T? initialValue;
  final FutureOr<Iterable<T>> Function(TextEditingValue) optionsBuilder;
  final String Function(T) displayStringForOption;
  final void Function(T?) onSelected;
  final String? Function(T?)? validator;
  final double width;
  final bool readOnly;

  const AutocompleteLabel({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    required this.optionsBuilder,
    required this.displayStringForOption,
    required this.onSelected,
    this.validator,
    this.width = 400,
    this.readOnly = false,
  });

  @override
  State<AutocompleteLabel<T>> createState() => _AutocompleteLabelState<T>();
}

class _AutocompleteLabelState<T extends Object>
    extends State<AutocompleteLabel<T>> {
  /// Owned by this widget (rather than by [Autocomplete]) so that a changed
  /// [AutocompleteLabel.initialValue] can be pushed into the visible text:
  /// Autocomplete only reads its own initialValue in initState.
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final GlobalKey<FormFieldState<T>> _fieldKey = GlobalKey<FormFieldState<T>>();

  String _displayString(T? value) =>
      value != null ? widget.displayStringForOption(value) : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _displayString(widget.initialValue),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(AutocompleteLabel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      // after the frame: writing the controller here notifies the TextFormField
      // below, whose Form would then be marked dirty during its own build
      final T? value = widget.initialValue;
      final String text = _displayString(value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.initialValue != value) return;
        if (_controller.text != text) _controller.text = text;
        _fieldKey.currentState?.didChange(value);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Wraps the user-provided [optionsBuilder] so that if this widget is
  /// unmounted while the async builder is in flight, the returned Future
  /// never completes. This prevents Flutter's [RawAutocomplete] from
  /// accessing [State.context] on a defunct State in `_announceSemantics`.
  Future<Iterable<T>> _safeOptionsBuilder(TextEditingValue value) async {
    final results = await widget.optionsBuilder(value);
    if (!mounted) {
      return Completer<Iterable<T>>().future;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      // keyed so didUpdateWidget can push a changed initialValue into the
      // field value: FormField, like Autocomplete, only reads it on init
      key: _fieldKey,
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (FormFieldState<T> field) {
        return Autocomplete<T>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: widget.readOnly
              ? (_) async => const Iterable.empty()
              : _safeOptionsBuilder,
          displayStringForOption: widget.displayStringForOption,
          onSelected: (T value) {
            field.didChange(value);
            widget.onSelected(value);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  readOnly: widget.readOnly,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hintText,
                    errorText: field.errorText,
                    suffixIcon: widget.readOnly
                        ? null
                        : textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  textController.clear();
                                  field.didChange(null);
                                  widget.onSelected(null);
                                },
                              )
                            : const Icon(Icons.search, size: 20),
                  ),
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: widget.width,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        key: Key('autocompleteOption$index'),
                        dense: true,
                        title: Text(widget.displayStringForOption(option)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
