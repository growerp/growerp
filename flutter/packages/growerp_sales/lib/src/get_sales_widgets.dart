/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_sales.dart';

/// Returns widget mappings for the sales package
Map<String, GrowerpWidgetBuilder> getSalesWidgets() {
  return {
    'OpportunityList': (args) => OpportunityList(key: getKeyFromArgs(args)),
  };
}
