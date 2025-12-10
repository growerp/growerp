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
  menuOptions: [
    MenuOption(
      menuOptionId: 'OA_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuOption(
      menuOptionId: 'OA_ORDERS',
      title: 'Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 20,
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
    MenuOption(
      menuOptionId: 'OA_ACCOUNTING',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 30,
    ),
    MenuOption(
      menuOptionId: 'OA_SHIPMENTS',
      title: 'Shipments',
      route: '/shipments',
      iconName: 'local_shipping',
      sequenceNum: 40,
    ),
    MenuOption(
      menuOptionId: 'OA_INVENTORY',
      title: 'Inventory',
      route: '/inventory',
      iconName: 'inventory',
      sequenceNum: 50,
    ),
    MenuOption(
      menuOptionId: 'OA_REQUESTS',
      title: 'Requests',
      route: '/requests',
      iconName: 'assignment',
      sequenceNum: 60,
    ),
  ],
);

/// Creates a static go_router for the order accounting example app
GoRouter createOrderAccountingExampleRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      if (!isAuthenticated && state.uri.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return DisplayMenuOption(
              menuConfiguration: orderAccountingMenuConfig,
              menuIndex: 0,
              actions: [
                IconButton(
                  key: const Key('logoutButton'),
                  icon: const Icon(
                    Icons.do_not_disturb,
                    key: Key('HomeFormAuth'),
                  ),
                  tooltip: 'Logout',
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              child: const OrderAccountingDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: orderAccountingMenuConfig,
              title: 'GrowERP Order & Accounting Example',
            );
          }
        },
      ),
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
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (
            int i = 0;
            i < orderAccountingMenuConfig.menuOptions.length;
            i++
          ) {
            if (orderAccountingMenuConfig.menuOptions[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: orderAccountingMenuConfig,
            menuIndex: menuIndex,
            actions: const [],
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/orders',
            builder: (context, state) => const FinDocList(
              key: Key('SalesOrder'),
              sales: true,
              docType: FinDocType.order,
            ),
          ),
          GoRoute(
            path: '/accounting',
            builder: (context, state) => const AccountingForm(),
            routes: [
              GoRoute(
                path: 'sales',
                builder: (context, state) => const FinDocList(
                  key: Key('SalesInvoice'),
                  sales: true,
                  docType: FinDocType.invoice,
                ),
              ),
              GoRoute(
                path: 'purchase',
                builder: (context, state) => const FinDocList(
                  key: Key('PurchaseInvoice'),
                  sales: false,
                  docType: FinDocType.invoice,
                ),
              ),
              GoRoute(
                path: 'sales_payments',
                builder: (context, state) => const FinDocList(
                  key: Key('SalesPayment'),
                  sales: true,
                  docType: FinDocType.payment,
                ),
              ),
              GoRoute(
                path: 'purchase_payments',
                builder: (context, state) => const FinDocList(
                  key: Key('PurchasePayment'),
                  sales: false,
                  docType: FinDocType.payment,
                ),
              ),
              GoRoute(
                path: 'ledger',
                builder: (context, state) => const FinDocList(
                  key: Key('Transaction'),
                  sales: true,
                  docType: FinDocType.transaction,
                ),
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) =>
                    const Center(child: Text("Reports")),
              ),
              GoRoute(
                path: 'setup',
                builder: (context, state) => const Center(child: Text("Setup")),
              ),
            ],
          ),
          GoRoute(
            path: '/shipments',
            builder: (context, state) => const FinDocList(
              key: Key('ShipmentsOut'),
              sales: true,
              docType: FinDocType.shipment,
            ),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) =>
                const LocationList(key: Key('LocationList')),
          ),
          GoRoute(
            path: '/requests',
            builder: (context, state) => const FinDocList(
              key: Key('Request'),
              sales: false,
              docType: FinDocType.request,
            ),
          ),
        ],
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
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _DashboardCard(
                    title: 'Orders',
                    iconName: 'shopping_cart',
                    route: '/orders',
                    stats:
                        'Sales: ${authenticate.stats?.openSlsOrders ?? 0}\n'
                        'Purchase: ${authenticate.stats?.openPurOrders ?? 0}',
                  );
                case 1:
                  return _DashboardCard(
                    title: 'Accounting',
                    iconName: 'account_balance',
                    route: '/accounting',
                    stats:
                        'Sales Invoices: ${authenticate.stats?.salesInvoicesNotPaidCount ?? 0}\n'
                        'Purchase: ${authenticate.stats?.purchInvoicesNotPaidCount ?? 0}',
                  );
                case 2:
                  return _DashboardCard(
                    title: 'Shipments',
                    iconName: 'local_shipping',
                    route: '/shipments',
                    stats:
                        'Incoming: ${authenticate.stats?.incomingShipments ?? 0}\n'
                        'Outgoing: ${authenticate.stats?.outgoingShipments ?? 0}',
                  );
                case 3:
                  return _DashboardCard(
                    title: 'Inventory',
                    iconName: 'inventory',
                    route: '/inventory',
                    stats:
                        'WH Locations: ${authenticate.stats?.whLocations ?? 0}',
                  );
                default:
                  return _DashboardCard(
                    title: 'Requests',
                    iconName: 'assignment',
                    route: '/requests',
                    stats: 'Requests: ${authenticate.stats?.requests ?? 0}',
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;
  final String stats;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child:
                      getIconFromRegistry(iconName) ??
                      const Icon(Icons.dashboard, size: 48),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  stats,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
