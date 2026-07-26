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

import 'package:growerp_core/growerp_core.dart';
import '../growerp_wiki.dart';

/// Returns widget mappings for the wiki package
Map<String, GrowerpWidgetBuilder> getWikiWidgets() {
  return {'WikiList': (args) => const WikiList()};
}

/// Returns widget metadata with icons for the wiki package
List<WidgetMetadata> getWikiWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'WikiList',
      description:
          'Browse and edit the wiki / OKF knowledge bundle pages '
          '(entity data model concepts and hand-authored notes)',
      iconName: 'menu_book',
      keywords: ['wiki', 'okf', 'knowledge', 'bundle', 'data model', 'docs'],
      builder: (args) => const WikiList(),
    ),
  ];
}
