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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'accounting_form.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');
  Bloc.observer = AppBlocObserver();

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Order & Accounting Example',
      router: createOrderAccountingExampleRouter(),
      extraDelegates: const [
        OrderAccountingLocalizations.delegate,
        InventoryLocalizations.delegate,
      ],
      extraBlocProviders: getOrderAccountingBlocProvidersExample(
        restClient,
        'AppAdmin',
      ),
    ),
  );
}

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
      children: [
        MenuItem(
          menuItemId: 'ORDER_ACCOUNTING',
          title: 'Order Accounting',
          iconName: 'accounting',
          sequenceNum: 10,
          widgetName: 'OrderAccounting',
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'OA_ACCOUNTING',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 30,
      widgetName: 'AccountingForm',
    ),
    MenuItem(
      menuItemId: 'OA_SHIPMENTS',
      title: 'Shipments',
      route: '/shipments',
      iconName: 'local_shipping',
      sequenceNum: 40,
      widgetName: 'FinDocList',
    ),
    MenuItem(
      menuItemId: 'OA_INVENTORY',
      title: 'Inventory',
      route: '/inventory',
      iconName: 'inventory',
      sequenceNum: 50,
      widgetName: 'LocationList',
    ),
    MenuItem(
      menuItemId: 'OA_REQUESTS',
      title: 'Requests',
      route: '/requests',
      iconName: 'assignment',
      sequenceNum: 60,
      widgetName: 'FinDocList',
    ),
  ],
);

/// Creates a static go_router for the order accounting example app using shared helper
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
      '/accounting' => const AccountingForm(),
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
      // FinDoc dialog route
      GoRoute(
        path: '/findoc',
        builder: (context, state) {
          final finDoc = state.extra as FinDoc?;
          return ShowFinDocDialog(finDoc ?? FinDoc());
        },
      ),
      // Printer route
      GoRoute(
        path: '/printer',
        builder: (context, state) {
          final finDoc = state.extra as FinDoc?;
          return PrintingForm(finDocIn: finDoc ?? FinDoc());
        },
      ),
      // Nested accounting routes
      GoRoute(
        path: '/accounting/sales',
        builder: (context, state) => const FinDocList(
          key: Key('SalesInvoice'),
          sales: true,
          docType: FinDocType.invoice,
        ),
      ),
      GoRoute(
        path: '/accounting/purchase',
        builder: (context, state) => const FinDocList(
          key: Key('PurchaseInvoice'),
          sales: false,
          docType: FinDocType.invoice,
        ),
      ),
      GoRoute(
        path: '/accounting/sales_payments',
        builder: (context, state) => const FinDocList(
          key: Key('SalesPayment'),
          sales: true,
          docType: FinDocType.payment,
        ),
      ),
      GoRoute(
        path: '/accounting/purchase_payments',
        builder: (context, state) => const FinDocList(
          key: Key('PurchasePayment'),
          sales: false,
          docType: FinDocType.payment,
        ),
      ),
      GoRoute(
        path: '/accounting/ledger',
        builder: (context, state) => const FinDocList(
          key: Key('Transaction'),
          sales: true,
          docType: FinDocType.transaction,
        ),
      ),
      GoRoute(
        path: '/accounting/ledger-accounts',
        builder: (context, state) =>
            const GlAccountList(key: Key('GlAccountList')),
      ),
      GoRoute(
        path: '/accounting/ledger-journal',
        builder: (context, state) =>
            const LedgerJournalList(key: Key('LedgerJournalListLedgerJournal')),
      ),
      GoRoute(
        path: '/accounting/reports',
        builder: (context, state) => const Center(child: Text("Reports")),
      ),
      GoRoute(
        path: '/accounting/setup',
        builder: (context, state) =>
            const PaymentTypeList(key: Key('PaymentTypeList')),
      ),
      GoRoute(
        path: '/accounting/setup/item-types',
        builder: (context, state) =>
            const ItemTypeList(key: Key('ItemTypeList')),
      ),
      GoRoute(
        path: '/purchase-orders',
        builder: (context, state) => const FinDocList(
          key: Key('PurchaseOrder'),
          sales: false,
          docType: FinDocType.order,
        ),
      ),
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

        final authenticate = state.authenticate!;
        return DashboardGrid(
          itemCount: 7,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return DashboardCard(
                  title: 'Orders',
                  iconName: 'shopping_cart',
                  route: '/orders',
                  stats:
                      'Sales: ${authenticate.stats?.openSlsOrders ?? 0}\n'
                      'Purchase: ${authenticate.stats?.openPurOrders ?? 0}',
                );
              case 1:
                return DashboardCard(
                  title: 'Purchase\nOrders',
                  iconName: 'shopping_cart',
                  route: '/purchase-orders',
                  stats: 'Open: ${authenticate.stats?.openPurOrders ?? 0}',
                );
              case 2:
                return DashboardCard(
                  title: 'Accounting',
                  iconName: 'account_balance',
                  route: '/accounting',
                  stats:
                      'Sales Invoices: ${authenticate.stats?.salesInvoicesNotPaidCount ?? 0}\n'
                      'Purchase: ${authenticate.stats?.purchInvoicesNotPaidCount ?? 0}',
                );
              case 3:
                return DashboardCard(
                  title: 'Shipments',
                  iconName: 'local_shipping',
                  route: '/shipments',
                  stats:
                      'Incoming: ${authenticate.stats?.incomingShipments ?? 0}\n'
                      'Outgoing: ${authenticate.stats?.outgoingShipments ?? 0}',
                );
              case 4:
                return DashboardCard(
                  title: 'Incoming\nShipments',
                  iconName: 'local_shipping',
                  route: '/incoming-shipments',
                  stats:
                      'Incoming: ${authenticate.stats?.incomingShipments ?? 0}',
                );
              case 5:
                return DashboardCard(
                  title: 'Inventory',
                  iconName: 'inventory',
                  route: '/inventory',
                  stats:
                      'WH Locations: ${authenticate.stats?.whLocations ?? 0}',
                );
              default:
                return DashboardCard(
                  title: 'Requests',
                  iconName: 'assignment',
                  route: '/requests',
                  stats: 'Requests: ${authenticate.stats?.requests ?? 0}',
                );
            }
          },
        );
      },
    );
  }
}
