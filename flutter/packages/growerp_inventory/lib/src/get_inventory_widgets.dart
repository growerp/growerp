/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_inventory.dart';

/// Returns widget mappings for the inventory package
Map<String, GrowerpWidgetBuilder> getInventoryWidgets() {
  return {
    'LocationList': (args) => LocationList(key: getKeyFromArgs(args)),
    'AssetList': (args) => AssetList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the inventory package
List<WidgetMetadata> getInventoryWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'LocationList',
      description: 'List of warehouse locations',
      iconName: 'location_pin',
      keywords: ['location', 'warehouse', 'storage', 'bin'],
      builder: (args) => LocationList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'AssetList',
      description: 'List of inventory assets',
      iconName: 'warehouse',
      keywords: ['asset', 'inventory', 'stock', 'equipment'],
      builder: (args) => AssetList(key: getKeyFromArgs(args)),
    ),
  ];
}
