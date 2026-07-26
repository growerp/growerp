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
import '../growerp_website.dart';

/// Returns widget mappings for the website package
Map<String, GrowerpWidgetBuilder> getWebsiteWidgets() {
  return {
    'WebsiteDialog': (args) => const WebsiteDialog(),
    'WebsiteFormList': (args) => WebsiteFormList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the website package
List<WidgetMetadata> getWebsiteWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'WebsiteDialog',
      description: 'Website configuration dialog',
      iconName: 'web',
      keywords: ['website', 'site', 'web', 'online'],
      builder: (args) => const WebsiteDialog(),
    ),
    WidgetMetadata(
      widgetName: 'WebsiteFormList',
      description: 'Website lead-capture forms: create forms and embed them '
          'on website pages to collect leads',
      iconName: 'dynamic_form',
      keywords: ['form', 'lead capture', 'website form', 'signup'],
      builder: (args) => WebsiteFormList(key: getKeyFromArgs(args)),
    ),
  ];
}
