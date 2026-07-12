/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
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
