/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_website.dart';

/// Returns widget mappings for the website package
Map<String, GrowerpWidgetBuilder> getWebsiteWidgets() {
  return {'WebsiteDialog': (args) => const WebsiteDialog()};
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
  ];
}
