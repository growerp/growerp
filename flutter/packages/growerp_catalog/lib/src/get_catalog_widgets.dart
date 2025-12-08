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
