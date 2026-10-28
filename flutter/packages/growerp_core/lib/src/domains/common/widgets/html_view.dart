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

/// Read-only display of raw html (website pages, emails), sized to its
/// content. Pure-Dart renderer: no css (Tailwind classes are ignored).
class HtmlView extends StatelessWidget {
  final String html;

  const HtmlView(this.html, {super.key});

  /// [html] without the FreeMarker markup the html parser would show as
  /// text: comments, directive tags (their content stays) and macro calls.
  static String clean(String html) => html
      .replaceAll(RegExp(r'<#--.*?-->', dotAll: true), '')
      .replaceAll(RegExp(r'</?[#@][^>]*>'), '');

  @override
  Widget build(BuildContext context) => HtmlWidget(clean(html));
}
