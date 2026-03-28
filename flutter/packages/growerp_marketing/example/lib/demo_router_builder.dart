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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

/// Canonical menu configuration for the Marketing demo app.
///
/// Used by both the production app (demo.dart) and all demo integration tests.
const marketingDemoMenuConfig = MenuConfiguration(
  menuConfigurationId: 'MARKETING_DEMO',
  appId: 'marketing_demo',
  name: 'GrowERP Marketing Demo',
  menuItems: [
    MenuItem(
      itemKey: 'MKT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'MarketingDemoDashboard',
    ),
    MenuItem(
      itemKey: 'MKT_PRODUCTS',
      title: 'Products',
      route: '/products',
      iconName: 'category',
      sequenceNum: 20,
      widgetName: 'ProductList',
    ),
    MenuItem(
      itemKey: 'MKT_SO',
      title: 'Sales Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 30,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MKT_PO',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MKT_IN_SHIP',
      title: 'Shipment-In',
      route: '/incoming-shipments',
      iconName: 'local_shipping',
      sequenceNum: 50,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MKT_OUT_SHIP',
      title: 'Shipment-out',
      route: '/shipments',
      iconName: 'outbound',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      itemKey: 'MKT_SALES_INVOICES',
      title: 'Sales Invoices',
      route: '/accounting/sales',
      iconName: 'receipt',
      sequenceNum: 70,
      widgetName: 'salesInvoiceList',
    ),
    MenuItem(
      itemKey: 'MKT_SALES_PAYMENTS',
      title: 'Sales Payments',
      route: '/accounting/sales_payments',
      iconName: 'payments',
      sequenceNum: 80,
      widgetName: 'salesPaymentList',
    ),
    MenuItem(
      itemKey: 'MKT_PURCHASE_INVOICES',
      title: 'Purchase Invoices',
      route: '/accounting/purchase',
      iconName: 'receipt',
      sequenceNum: 90,
      widgetName: 'purchaseInvoiceList',
    ),
    MenuItem(
      itemKey: 'MKT_PURCHASE_PAYMENTS',
      title: 'Purchase Payments',
      route: '/accounting/purchase_payments',
      iconName: 'payments',
      sequenceNum: 100,
      widgetName: 'purchasePaymentList',
    ),
    MenuItem(
      itemKey: 'MKT_LEDGER',
      title: 'Transactions',
      route: '/accounting/ledger',
      iconName: 'receipt_long',
      sequenceNum: 110,
      widgetName: 'transactionList',
    ),
  ],
);

/// Creates a static go_router for the marketing demo app.
///
/// Used by both the production app (demo.dart) and all demo integration tests.
GoRouter createMarketingDemoRouter() {
  return createStaticAppRouter(
    menuConfig: marketingDemoMenuConfig,
    appTitle: 'GrowERP Marketing Demo',
    dashboard: const MarketingDemoDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/products' => const ProductList(),
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
      '/accounting/sales' => const FinDocList(
          key: Key('SalesInvoice'),
          sales: true,
          docType: FinDocType.invoice,
        ),
      '/accounting/sales_payments' => const FinDocList(
          key: Key('SalesPayment'),
          sales: true,
          docType: FinDocType.payment,
        ),
      '/accounting/purchase' => const FinDocList(
          key: Key('PurchaseInvoice'),
          sales: false,
          docType: FinDocType.invoice,
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
      _ => const MarketingDemoDashboard(),
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

/// Dashboard for the marketing demo app.
class MarketingDemoDashboard extends StatelessWidget {
  const MarketingDemoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = marketingDemoMenuConfig.menuItems
            .where((item) =>
                item.isActive && item.route != null && item.route != '/')
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          key: const Key('MarketingDemoDashboard'),
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardItems,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
          ),
        );
      },
    );
  }
}
