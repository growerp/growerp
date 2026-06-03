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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_manufacturing.dart';

Map<String, GrowerpWidgetBuilder> getManufacturingWidgets() {
  return {
    'BomList': (args) => BomList(key: getKeyFromArgs(args)),
    'WorkOrderList': (args) => WorkOrderList(key: getKeyFromArgs(args)),
    'RoutingList': (args) => RoutingList(key: getKeyFromArgs(args)),
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
    WidgetMetadata(
      widgetName: 'RoutingList',
      description: 'Production routings - ordered sequence of operations',
      iconName: 'route',
      keywords: ['routing', 'operations', 'work center', 'sequence'],
      builder: (args) => RoutingList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'BomDialog',
      description: 'Create or edit a Bill of Materials. Pass bomId to edit an '
          'existing BOM; omit it to create a new one.',
      iconName: 'schema',
      keywords: ['add bom', 'new bom', 'create bom', 'edit bom'],
      parameters: {'bomId': 'open this BOM for editing; omit to create new'},
      builder: (args) {
        final id = (args?['bomId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return const BomDialog();
        return AsyncRecordDialog<Bom>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getBoms(search: id, limit: 1);
            return r.boms.isNotEmpty ? r.boms.first : null;
          },
          onLoaded: (b) => BomDialog(bom: b),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'WorkOrderDialog',
      description: 'Create or edit a production work order. Pass workOrderId to '
          'edit an existing work order; omit it to create a new one.',
      iconName: 'precision_manufacturing',
      keywords: ['add work order', 'new work order', 'create work order', 'edit work order'],
      parameters: {'workOrderId': 'open this work order for editing; omit to create new'},
      builder: (args) {
        final id = (args?['workOrderId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return WorkOrderDialog(WorkOrder());
        return AsyncRecordDialog<WorkOrder>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getWorkOrder(search: id, limit: 1);
            return r.workOrders.isNotEmpty ? r.workOrders.first : null;
          },
          onLoaded: (w) => WorkOrderDialog(w),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'RoutingDialog',
      description: 'Create or edit a production routing. Pass routingId to edit '
          'an existing routing; omit it to create a new one.',
      iconName: 'route',
      keywords: ['add routing', 'new routing', 'create routing', 'edit routing'],
      parameters: {'routingId': 'open this routing for editing; omit to create new'},
      builder: (args) {
        final id = (args?['routingId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return RoutingDialog(Routing());
        return AsyncRecordDialog<Routing>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getRoutings(search: id, limit: 1);
            return r.routings.isNotEmpty ? r.routings.first : null;
          },
          onLoaded: (r) => RoutingDialog(r),
        );
      },
    ),
  ];
}
