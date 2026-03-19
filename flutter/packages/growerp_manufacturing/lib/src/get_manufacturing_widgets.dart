/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:growerp_core/growerp_core.dart';

import '../growerp_manufacturing.dart';

Map<String, GrowerpWidgetBuilder> getManufacturingWidgets() {
  return {
    'BomList': (args) => BomList(key: getKeyFromArgs(args)),
    'WorkOrderList': (args) => WorkOrderList(key: getKeyFromArgs(args)),
  };
}

List<WidgetMetadata> getManufacturingWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'BomList',
      description: 'Bill of Materials - list of components for each product',
      iconName: 'schema',
      keywords: ['bom', 'bill of materials', 'component', 'recipe'],
      builder: (args) => BomList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'WorkOrderList',
      description: 'Production work orders',
      iconName: 'precision_manufacturing',
      keywords: ['work order', 'production', 'manufacturing', 'run'],
      builder: (args) => WorkOrderList(key: getKeyFromArgs(args)),
    ),
  ];
}
