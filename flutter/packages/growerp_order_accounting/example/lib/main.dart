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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'acct_menu_option_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  await Hive.initFlutter();

  runApp(TopApp(
    restClient: RestClient(await buildDioClient()),
    classificationId: 'AppAdmin',
    chatServer: ChatServer(),
    title: 'GrowERP Order and Accounting.',
    router: generateRoute,
    menuOptions: menuOptions,
    extraDelegates: const [OrderAccountingLocalizations.delegate],
  ));
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
        form: const FinDocListForm(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: '\nSales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocListForm(
            key: Key('PurchaseOrder'), sales: false, docType: FinDocType.order),
        label: '\nPurchase orders',
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
];

// routing
Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    debugPrint('>>>NavigateTo { ${settings.name} '
        'with: ${settings.arguments.toString()} }');
  }
  switch (settings.name) {
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
    case '/printer':
      return MaterialPageRoute(
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
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
        ]);
      }
      return const LoadingIndicator();
    });
  }
}
