/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_catalog.dart';

/// Returns widget mappings for the catalog package
Map<String, GrowerpWidgetBuilder> getCatalogWidgets() {
  return {
    'ProductList': (args) => ProductList(key: getKeyFromArgs(args)),
    'CategoryList': (args) => CategoryList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the catalog package
List<WidgetMetadata> getCatalogWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'ProductList',
      description: 'List of products in the catalog',
      iconName: 'inventory',
      keywords: ['product', 'item', 'catalog', 'goods'],
      builder: (args) => ProductList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'CategoryList',
      description: 'List of product categories',
      iconName: 'category',
      keywords: ['category', 'classification', 'group'],
      builder: (args) => CategoryList(key: getKeyFromArgs(args)),
    ),
  ];
}
