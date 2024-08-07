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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  await Hive.initFlutter();
  RestClient restClient = RestClient(await buildDioClient());
  ChatServer chatServer = ChatServer();
  Bloc.observer = AppBlocObserver();

  runApp(Phoenix(
    child: TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatServer: chatServer,
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
  ));
}

List<BlocProvider> getOrderAccountingBlocProvidersExample(
    restClient, classificationId) {
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
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const MainMenuForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Orders',
    route: '/orders',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
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
      image: 'packages/growerp_core/images/accountingGrey.png',
      selectedImage: 'packages/growerp_core/images/accounting.png',
      title: 'Accounting',
      route: '/accounting',
      readGroups: [UserGroup.admin]),
  MenuOption(
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Shipments',
    route: '/shipments',
    readGroups: [UserGroup.admin, UserGroup.employee],
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
      image: 'packages/growerp_core/images/supplierGrey.png',
      selectedImage: 'packages/growerp_core/images/supplier.png',
      title: 'Inventory',
      route: '/inventory',
      readGroups: [
        UserGroup.admin,
        UserGroup.employee,
      ],
      child: const LocationList()),
  MenuOption(
    image: 'packages/growerp_core/images/accountingGrey.png',
    selectedImage: 'packages/growerp_core/images/accounting.png',
    title: 'Requests',
    route: '/requests',
    readGroups: [UserGroup.admin],
    child: const FinDocList(
        key: Key('Reuquest'), sales: false, docType: FinDocType.request),
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
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        Authenticate authenticate = state.authenticate!;
        return DashBoardForm(dashboardItems: [
          makeDashboardItem('dbOrders', context, menuOptions[1], [
            "Sales Orders: ${authenticate.stats?.openSlsOrders ?? 0}",
            "Customers: ${authenticate.stats?.customers ?? 0}",
            "Purchase Orders: ${authenticate.stats?.openPurOrders ?? 0}",
            "Suppliers: ${authenticate.stats?.suppliers ?? 0}",
          ]),
          makeDashboardItem('dbAccounting', context, menuOptions[2], [
            "Sales open invoices: \n"
                "${authenticate.company!.currency?.currencyId} "
                "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                "(${authenticate.stats?.salesInvoicesNotPaidCount ?? 0})",
            "Purchase unpaid invoices: \n"
                "${authenticate.company!.currency?.currencyId} "
                "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                "(${authenticate.stats?.purchInvoicesNotPaidCount ?? 0})",
          ]),
          makeDashboardItem('dbShipments', context, menuOptions[3], [
            "Incoming Shipments: ${authenticate.stats?.incomingShipments ?? 0}",
            "Outgoing Shipments: ${authenticate.stats?.outgoingShipments ?? 0}",
          ]),
          makeDashboardItem('dbInventory', context, menuOptions[4], [
            "Wh Locations: ${authenticate.stats?.whLocations ?? 0}",
          ]),
          makeDashboardItem('dbRequests', context, menuOptions[5], [
            "Requests: ${authenticate.stats?.requests ?? 0}",
          ]),
        ]);
      }
      return const LoadingIndicator();
    });
  }
}
