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
