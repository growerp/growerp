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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

List<BlocProvider> getOrderAccountingBlocProvidersExample(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getInventoryBlocProviders(restClient, classificationId),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
  ];
}

/// Static menu configuration
const orderAccountingMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ORDER_ACCOUNTING_EXAMPLE',
  appId: 'order_accounting_example',
  name: 'Order & Accounting Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'OA_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'OrderAccountingDashboard',
    ),
    MenuItem(
      menuItemId: 'OA_ORDERS',
      title: 'Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 20,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_PURCH_ORDERS',
      title: 'Purchase Orders',
      route: '/purchase-orders',
      iconName: 'shopping_bag',
      sequenceNum: 25,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_SALES_INV',
      title: 'Sales Invoices',
      route: '/accounting/sales',
      iconName: 'attach_money',
      sequenceNum: 30,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_PURCH_INV',
      title: 'Purchase Invoices',
      route: '/accounting/purchase',
      iconName: 'money_off',
      sequenceNum: 35,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_SALES_PAY',
      title: 'Sales Payments',
      route: '/accounting/sales_payments',
      iconName: 'input',
      sequenceNum: 38,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_PURCH_PAY',
      title: 'Purchase Payments',
      route: '/accounting/purchase_payments',
      iconName: 'output',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_LEDGER',
      title: 'Ledger',
      route: '/accounting/ledger',
      iconName: 'account_balance_wallet',
      sequenceNum: 45,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_LEDGER_ACCTS',
      title: 'Ledger Accounts',
      route: '/accounting/ledger-accounts',
      iconName: 'account_tree',
      sequenceNum: 50,
      widgetName: 'GlAccountList',
    ),
    MenuItem(
      menuItemId: 'OA_LEDGER_JOURNAL',
      title: 'Ledger Journal',
      route: '/accounting/ledger-journal',
      iconName: 'receipt_long',
      sequenceNum: 55,
      widgetName: 'LedgerJournalList',
    ),
    MenuItem(
      menuItemId: 'OA_REPORTS',
      title: 'Revenue/Expenses',
      route: '/accounting/reports',
      iconName: 'summarize',
      sequenceNum: 60,
      widgetName: 'RevenueExpense',
    ),
    MenuItem(
      menuItemId: 'OA_SETUP',
      title: 'Setup',
      route: '/accounting/setup',
      iconName: 'settings',
      sequenceNum: 65,
      widgetName: 'PaymentTypeList',
    ),
    MenuItem(
      menuItemId: 'OA_ITEM_TYPES',
      title: 'Item Types',
      route: '/accounting/setup/item-types',
      iconName: 'list',
      sequenceNum: 70,
      widgetName: 'ItemTypeList',
    ),
    MenuItem(
      menuItemId: 'OA_SHIPMENTS',
      title: 'Shipments',
      route: '/shipments',
      iconName: 'local_shipping',
      sequenceNum: 75,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_INVENTORY',
      title: 'Inventory',
      route: '/inventory',
      iconName: 'inventory',
      sequenceNum: 80,
      widgetName: 'LocationList',
    ),
    MenuItem(
      menuItemId: 'OA_REQUESTS',
      title: 'Requests',
      route: '/requests',
      iconName: 'assignment',
      sequenceNum: 85,
      widgetName: 'FinDocList',
    ),
  ],
);

/// Creates a static go_router for the order accounting example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createOrderAccountingExampleRouter() {
  return createStaticAppRouter(
    menuConfig: orderAccountingMenuConfig,
    appTitle: 'GrowERP Order & Accounting Example',
    dashboard: const OrderAccountingDashboard(),
    widgetBuilder: (route) => switch (route) {
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
      '/accounting/sales' => const FinDocList(
        key: Key('SalesInvoice'),
        sales: true,
        docType: FinDocType.invoice,
      ),
      '/accounting/purchase' => const FinDocList(
        key: Key('PurchaseInvoice'),
        sales: false,
        docType: FinDocType.invoice,
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
      '/accounting/ledger-accounts' => const GlAccountList(
        key: Key('GlAccountList'),
      ),
      '/accounting/ledger-journal' => const LedgerJournalList(
        key: Key('LedgerJournalListLedgerJournal'),
      ),
      '/accounting/reports' => const Center(child: Text("Reports")),
      '/accounting/setup' => const PaymentTypeList(),
      '/accounting/setup/item-types' => const ItemTypeList(),
      '/shipments' => const FinDocList(
        key: Key('ShipmentsOut'),
        sales: true,
        docType: FinDocType.shipment,
      ),
      '/inventory' => const LocationList(),
      '/requests' => const FinDocList(
        key: Key('FinDocListRequest'),
        sales: false,
        docType: FinDocType.request,
      ),
      _ => const OrderAccountingDashboard(),
    },
    additionalRoutes: [
      // Dialog-style routes that should NOT show the nav rail
      GoRoute(
        path: '/findoc',
        builder: (context, state) {
          final finDoc = state.extra as FinDoc?;
          return ShowFinDocDialog(finDoc ?? FinDoc());
        },
      ),
      GoRoute(
        path: '/printer',
        builder: (context, state) {
          final finDoc = state.extra as FinDoc?;
          return PrintingForm(finDocIn: finDoc ?? FinDoc());
        },
      ),
    ],
    shellRoutes: [
      GoRoute(
        path: '/incoming-shipments',
        builder: (context, state) => const FinDocList(
          key: Key('ShipmentsIn'),
          sales: false,
          docType: FinDocType.shipment,
        ),
      ),
    ],
  );
}

/// Simple dashboard for order accounting example
class OrderAccountingDashboard extends StatelessWidget {
  const OrderAccountingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        return DashboardGrid(
          items: orderAccountingMenuConfig.menuItems
              .where((item) => item.route != '/' && item.route != null)
              .toList(),
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
