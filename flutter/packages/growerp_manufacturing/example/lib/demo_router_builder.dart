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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

/// Canonical menu configuration for the Manufacturing demo app.
///
/// Used by both the production app (demo.dart) and all demo integration tests.
const mfgDemoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'MFG_DEMO',
  appId: 'manufacturing_demo',
  name: 'GrowERP Manufacturing Demo',
  menuItems: [
    MenuItem(
      itemKey: 'MFG_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'MfgDemoDashboard',
    ),
    MenuItem(
      itemKey: 'MFG_BOM',
      title: 'BOM',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 20,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'MFG_WO',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 30,
      widgetName: 'WorkOrderList',
    ),
    MenuItem(
      itemKey: 'MFG_ROUTING',
      title: 'Routings',
      route: '/manufacturing/routing',
      iconName: 'route',
      sequenceNum: 35,
      widgetName: 'RoutingList',
    ),
    MenuItem(
      itemKey: 'MFG_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 50,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_IN_SHIP',
      title: 'Shipment-In',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_OUT_SHIP',
      title: 'Shipment-out',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 70,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_SALES_PAY',
      title: 'Sales Payments',
      route: '/accounting/sales_payments',
      iconName: 'input',
      sequenceNum: 80,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_PURCH_PAY',
      title: 'Purchase Payments',
      route: '/accounting/purchase_payments',
      iconName: 'output',
      sequenceNum: 90,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MFG_LEDGER',
      title: 'Ledger',
      route: '/accounting/ledger',
      iconName: 'account_balance_wallet',
      sequenceNum: 100,
      widgetName: 'FinDocList',
    ),
  ],
);

/// Creates a static go_router for the manufacturing demo app.
///
/// Used by both the production app (demo.dart) and all demo integration tests.
GoRouter createMfgDemoRouter() {
  return createStaticAppRouter(
    menuConfig: mfgDemoMenuConfig,
    appTitle: 'GrowERP Manufacturing Demo',
    dashboard: const MfgDemoDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/manufacturing/bom' => const BomList(),
      '/manufacturing/workOrder' => const WorkOrderList(),
      '/manufacturing/routing' => const RoutingList(),
      '/orders' => const FinDocList(
          key: Key('SalesOrder'),
          sales: true,
          docType: FinDocType.order,
        ),
      '/purchase-orders' => const FinDocList(
          key: Key('PurchaseOrder'),
          sales: false,
          docType: FinDocType.order,
        ),
      '/shipments' => const FinDocList(
          key: Key('ShipmentsOut'),
          sales: true,
          docType: FinDocType.shipment,
        ),
      '/incoming-shipments' => const FinDocList(
          key: Key('ShipmentsIn'),
          sales: false,
          docType: FinDocType.shipment,
        ),
      '/accounting/sales_payments' => const FinDocList(
          key: Key('SalesPayment'),
          sales: true,
          docType: FinDocType.payment,
        ),
      '/accounting/purchase_payments' => const FinDocList(
          key: Key('PurchasePayment'),
          sales: false,
          docType: FinDocType.payment,
        ),
      '/accounting/ledger' => const FinDocList(
          key: Key('Transaction'),
          sales: true,
          docType: FinDocType.transaction,
        ),
      _ => const MfgDemoDashboard(),
    },
    additionalRoutes: [
      GoRoute(
        path: '/findoc',
        builder: (context, state) =>
            ShowFinDocDialog(state.extra as FinDoc? ?? FinDoc()),
      ),
    ],
  );
}

/// Dashboard for the manufacturing demo app.
class MfgDemoDashboard extends StatelessWidget {
  const MfgDemoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = mfgDemoMenuConfig.menuItems
            .where((item) =>
                item.isActive && item.route != null && item.route != '/')
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          key: const Key('MfgDemoDashboard'),
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardItems,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
            chartBuilder: (route) {
              if (route == '/accounting/ledger') {
                return const RevenueExpenseChartMini();
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
