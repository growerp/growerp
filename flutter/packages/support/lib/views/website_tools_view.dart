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
import '../src/website_conversion/website_conversion.dart';
import '../src/website_translation/website_translation.dart';

/// Support App View: "Website Tools" — combines the two previously separate
/// menu items (Website Generator, Website Translation) behind one entry with
/// two tabs, since both operate on the same tenant's website.
class WebsiteToolsView extends StatelessWidget {
  const WebsiteToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(key: Key('websiteToolsGeneratorTab'), text: 'Generator'),
              Tab(key: Key('websiteToolsTranslationTab'), text: 'Translation'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                WebsiteConversionList(),
                WebsiteTranslationList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
