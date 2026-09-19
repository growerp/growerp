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
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// Raw HTML source editor with a live rendered preview, split side-by-side
/// on wide screens and stacked on phones. Mirrors the raw-text/preview split
/// already used for markdown content editing, but for HTML source.
///
/// Note: this uses a pure-Dart HTML renderer (no webview), so it keeps
/// working on every GrowERP target platform including Linux/Windows desktop.
/// FreeMarker directives (e.g. `<#if>`, `${var}`) are not evaluated - they
/// either show as literal text or are dropped by the lenient HTML parser -
/// but surrounding static HTML renders correctly.
class HtmlSourceEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool isPhone;
  final Key? inputKey;
  final String? inputLabel;
  final bool monospace;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const HtmlSourceEditor({
    super.key,
    required this.controller,
    required this.isPhone,
    this.inputKey,
    this.inputLabel,
    this.monospace = true,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final input = TextFormField(
      key: inputKey,
      controller: controller,
      autofocus: autofocus,
      style: monospace
          ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
          : null,
      decoration: InputDecoration(labelText: inputLabel ?? 'HTML'),
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
    );

    final preview = ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(style: BorderStyle.solid, width: 0.80),
        ),
        child: SingleChildScrollView(
          child: HtmlWidget(controller.text),
        ),
      ),
    );

    if (isPhone) {
      return Column(
        children: [
          Expanded(child: input),
          const SizedBox(height: 10),
          Expanded(child: preview),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: input),
        const SizedBox(width: 20),
        Expanded(child: preview),
      ],
    );
  }
}
