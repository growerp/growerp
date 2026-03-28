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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

/// Localization delegates for the liner example.
final List<LocalizationsDelegate> linerExampleDelegates = [
  ManufacturingLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  CatalogLocalizations.delegate,
];

/// Canonical menu configuration for the Liner example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const linerExampleMenuConfig = MenuConfiguration(
  menuConfigurationId: 'LINER_EXAMPLE',
  appId: 'liner_example',
  name: 'GrowERP Liner Example',
  menuItems: [
    MenuItem(
      itemKey: 'LINER_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'LinerExampleDashboard',
    ),
    MenuItem(
      itemKey: 'LINER_TYPES',
      title: 'Liner Types',
      route: '/liner/linerType',
      iconName: 'layers',
      sequenceNum: 20,
      widgetName: 'LinerTypeList',
    ),
    MenuItem(
      itemKey: 'LINER_ROUTING',
      title: 'Routing',
      route: '/manufacturing/routing',
      iconName: 'route',
      sequenceNum: 30,
      widgetName: 'RoutingList',
    ),
    MenuItem(
      itemKey: 'LINER_BOM',
      title: 'BOM',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 40,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'LINER_WO',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 50,
      widgetName: 'WorkOrderList',
    ),
    MenuItem(
      itemKey: 'LINER_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 70,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_IN_SHIP',
      title: 'Shipment-In',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 80,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_OUT_SHIP',
      title: 'Shipment-out',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 90,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'LINER_SALES_PAYMENTS',
      title: 'Sales Payments',
      route: '/accounting/sales_payments',
      iconName: 'payments',
      sequenceNum: 91,
      widgetName: 'salesPaymentList',
    ),
    MenuItem(
      itemKey: 'LINER_PURCHASE_PAYMENTS',
      title: 'Purchase Payments',
      route: '/accounting/purchase_payments',
      iconName: 'payments',
      sequenceNum: 95,
      widgetName: 'purchasePaymentList',
    ),
    MenuItem(
      itemKey: 'LINER_LEDGER',
      title: 'Transactions',
      route: '/accounting/ledger',
      iconName: 'receipt_long',
      sequenceNum: 97,
      widgetName: 'transactionList',
    ),
    MenuItem(
      itemKey: 'LINER_ACCT',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 100,
    ),
  ],
);

/// Creates a static go_router for the liner example app.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createLinerExampleRouter() {
  return createStaticAppRouter(
    menuConfig: linerExampleMenuConfig,
    appTitle: 'GrowERP Liner Example',
    dashboard: const LinerExampleDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/liner/linerType' => const LinerTypeList(),
      '/manufacturing/routing' => const RoutingList(),
      '/manufacturing/bom' => const BomList(),
      '/manufacturing/workOrder' => WorkOrderList(
          extraTabBuilder: (workOrder) => [
            SizedBox(
              height: 300,
              child: LinerPanelList(workEffortId: workOrder.workEffortId),
            ),
          ],
          extraActionBuilder: (workOrder) => [
            Tooltip(
              message: 'Print Production Order',
              child: IconButton(
                key: const Key('printProductionOrder'),
                icon: const Icon(Icons.print),
                onPressed: () => printProductionOrder(workOrder),
              ),
            ),
          ],
        ),
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
      '/accounting' => const AccountingDashboard(),
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
      _ => const LinerExampleDashboard(),
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

/// Dashboard for the liner example app.
class LinerExampleDashboard extends StatelessWidget {
  const LinerExampleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = linerExampleMenuConfig.menuItems
            .where(
                (item) => item.isActive && item.route != null && item.route != '/')
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          key: const Key('LinerExampleDashboard'),
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardItems,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
            chartBuilder: (route) {
              if (route == '/accounting') {
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
