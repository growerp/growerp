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
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'acct_menu_option_data.dart';

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
      title: 'GrowERP Order and Accounting.',
      router: generateRoute,
      menuOptions: menuOptions,
      extraDelegates: const [
        OrderAccountingLocalizations.delegate,
        InventoryLocalizations.delegate
      ],
      extraBlocProviders:
          getOrderAccountingBlocProvidersExample(restClient, 'AppAdmin'),
    ),
  );
}

List<BlocProvider> getOrderAccountingBlocProvidersExample(
    RestClient restClient, String classificationId) {
  return [
    ...getInventoryBlocProviders(restClient, classificationId),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
  ];
}

// Menu definition
List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee, UserGroup.other],
    child: const MainMenuForm(),
  ),
  MenuOption(
    key: 'dbOrders',
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Orders',
    route: '/orders',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: 'Sales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
            key: Key('PurchaseOrder'), sales: false, docType: FinDocType.order),
        label: 'Purchase orders',
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
      key: 'dbAccounting',
      image: 'packages/growerp_core/images/accountingGrey.png',
      selectedImage: 'packages/growerp_core/images/accounting.png',
      title: 'Accounting',
      route: '/accounting',
      userGroups: [UserGroup.admin]),
  MenuOption(
    key: 'dbShipments',
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Shipments',
    route: '/shipments',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
            key: Key('ShipmentsOut'),
            sales: true,
            docType: FinDocType.shipment),
        label: 'Outgoing shipments',
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocList(
            key: Key('ShipmentsIn'),
            sales: false,
            docType: FinDocType.shipment),
        label: 'Incoming shipments',
        icon: const Icon(Icons.call_received),
      ),
    ],
  ),
  MenuOption(
      key: 'dbInventory',
      image: 'packages/growerp_core/images/supplierGrey.png',
      selectedImage: 'packages/growerp_core/images/supplier.png',
      title: 'Inventory',
      route: '/inventory',
      userGroups: [
        UserGroup.admin,
        UserGroup.employee,
      ],
      child: const LocationList()),
  MenuOption(
    key: 'dbRequests',
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Requests',
    route: '/requests',
    userGroups: [UserGroup.admin],
    child: const FinDocList(
        key: Key('Request'), sales: false, docType: FinDocType.request),
  ),
];

// routing
Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint('>>>NavigateTo { ${settings.name} '
      'with: ${settings.arguments.toString()} }');
  switch (settings.name) {
    case '/findoc':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => ShowFinDocDialog(settings.arguments as FinDoc));
    case '/':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/company':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/user':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/orders':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/requests':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 5));
    case '/shipments':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    case '/printer':
      return MaterialPageRoute(
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    case '/inventory':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/accounting':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: acctMenuOptions));
    case '/acctSales':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 1, tabIndex: 0));
    case '/acctPurchase':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 2, tabIndex: 0));
    case '/acctLedger':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 0));
    case '/acctLedgerAccounts':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 1));
    case '/acctLedgerTransactions':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 2));
    case '/acctLedgerJournal':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 3, tabIndex: 3));
    case '/acctReports':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 4, tabIndex: 0));
    case '/acctSetup':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: acctMenuOptions, menuIndex: 5, tabIndex: 0));
    default:
      return coreRoute(settings);
  }
}

// main menu
class MainMenuForm extends StatelessWidget {
  const MainMenuForm({super.key});

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    List<Widget> dashboardItems = [];

    for (final option in menuOptions) {
      if (option.userGroups!.contains(authenticate.user?.userGroup!)) {
        switch (option.key) {
          case 'dbOrders':
            dashboardItems
                .add(makeDashboardItem(option.key ?? '', context, option, [
              "Sales Orders: ${authenticate.stats?.openSlsOrders ?? 0}",
              "Customers: ${authenticate.stats?.customers ?? 0}",
              "Purchase Orders: ${authenticate.stats?.openPurOrders ?? 0}",
              "Suppliers: ${authenticate.stats?.suppliers ?? 0}"
            ]));
          case 'dbAccounting':
            dashboardItems
                .add(makeDashboardItem(option.key ?? '', context, option, [
              "Sales open invoices: \n"
                  "${authenticate.company!.currency?.currencyId} "
                  "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                  "(${authenticate.stats?.salesInvoicesNotPaidCount ?? 0})",
              "Purchase unpaid invoices: \n"
                  "${authenticate.company!.currency?.currencyId} "
                  "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                  "(${authenticate.stats?.purchInvoicesNotPaidCount ?? 0})",
            ]));
          case 'dbShipments':
            dashboardItems
                .add(makeDashboardItem(option.key ?? '', context, option, [
              "Incoming Shipments: ${authenticate.stats?.incomingShipments ?? 0}",
              "Outgoing Shipments: ${authenticate.stats?.outgoingShipments ?? 0}"
            ]));
          case 'dbInventory':
            dashboardItems.add(makeDashboardItem(
                option.key ?? '',
                context,
                option,
                ["Wh Locations: ${authenticate.stats?.whLocations ?? 0}"]));
          case 'dbRequests':
            dashboardItems.add(makeDashboardItem(option.key ?? '', context,
                option, ["Requests: ${authenticate.stats?.requests ?? 0}"]));
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: DashBoardForm(dashboardItems: dashboardItems)),
      ],
    );
  }
}
