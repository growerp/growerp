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
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_core/growerp_core.dart' as cat;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  runApp(Phoenix(
      child: TopApp(
          dbServer: APIRepository(),
          chatServer: ChatServer(),
          title: 'GrowERP.',
          router: generateRoute,
          menuOptions: menuOptions)));
}

// Menu definition
List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    child: const MainMenuForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: 'Company',
    route: '/company',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: CompanyForm(FormArguments()),
        label: 'Company Info',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Admin'),
          userGroup: UserGroup.Admin,
        ),
        label: 'Admins',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Employee'),
          userGroup: UserGroup.Employee,
        ),
        label: 'Employees',
        icon: const Icon(Icons.school),
      ),
    ],
  ),
  MenuOption(
      image: 'packages/growerp_core/images/productsGrey.png',
      selectedImage: 'packages/growerp_core/images/products.png',
      title: 'Catalog',
      route: '/catalog',
      readGroups: [
        UserGroup.Admin,
        UserGroup.SuperAdmin,
        UserGroup.Employee
      ],
      writeGroups: [
        UserGroup.Admin
      ],
      tabItems: [
        TabItem(
          form: const ProductListForm(),
          label: 'Products',
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const AssetListForm(),
          label: 'Assets',
          icon: const Icon(Icons.money),
        ),
        TabItem(
          form: const CategoryListForm(),
          label: 'Categories',
          icon: const Icon(Icons.business),
        ),
      ]),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Orders',
    route: '/orders',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin],
    tabItems: [
      TabItem(
        form: const FinDocListForm(
            key: Key('SalesOrder'), sales: true, docType: FinDocType.order),
        label: '\nSales orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Customer'),
          userGroup: UserGroup.Customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const FinDocListForm(
            key: Key('PurchaseOrder'), sales: false, docType: FinDocType.order),
        label: '\nPurchase orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Supplier'),
          userGroup: UserGroup.Supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Inventory',
    route: '/inventory',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    tabItems: [
      TabItem(
        form: const FinDocListForm(
            key: Key('ShipmentsOut'),
            sales: true,
            docType: FinDocType.shipment),
        label: '\nOutgoing shipments',
        icon: const Icon(Icons.send),
      ),
      TabItem(
        form: const FinDocListForm(
            key: Key('ShipmentsIn'),
            sales: false,
            docType: FinDocType.shipment),
        label: '\nIncoming shipments',
        icon: const Icon(Icons.call_received),
      ),
      TabItem(
        form: const LocationListForm(),
        label: '\nWH Locations',
        icon: const Icon(Icons.location_pin),
      ),
    ],
  ),
  MenuOption(
      image: 'packages/growerp_core/images/accountingGrey.png',
      selectedImage: 'packages/growerp_core/images/accounting.png',
      title: 'Accounting',
      route: '/accounting',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
  MenuOption(
      image: 'packages/growerp_core/images/infoGrey.png',
      selectedImage: 'packages/growerp_core/images/info.png',
      title: 'About',
      route: '/about',
      readGroups: [UserGroup.Admin, UserGroup.SuperAdmin]),
];

// routing
Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    print('>>>NavigateTo { ${settings.name} '
        'with: ${settings.arguments.toString()} }');
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/company':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/catalog':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
    case '/category':
      return MaterialPageRoute(
          builder: (context) =>
              CategoryDialog(settings.arguments as cat.Category));
    case '/orders':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    case '/inventory':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 4, tabIndex: 0));
    case '/printer':
      return MaterialPageRoute(
          builder: (context) =>
              PrintingForm(finDocIn: settings.arguments as FinDoc));
    case '/accounting':
      return MaterialPageRoute(builder: (context) => const AccountingForm());
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
          makeDashboardItem(
            'dbCompany',
            context,
            menuOptions[1],
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Administrators: ${authenticate.stats?.admins ?? 0}",
            "Other Employees: ${authenticate.stats?.employees ?? 0}",
            "",
          ),
          makeDashboardItem(
            'dbCatalog',
            context,
            menuOptions[2],
            "Categories: ${authenticate.stats?.categories ?? 0}",
            "Products: ${authenticate.stats?.products ?? 0}",
            "Assets: ${authenticate.stats?.assets ?? 0}",
            "",
          ),
          makeDashboardItem(
            'dbOrders',
            context,
            menuOptions[3],
            "Sales Orders: ${authenticate.stats?.openSlsOrders ?? 0}",
            "Customers: ${authenticate.stats?.customers ?? 0}",
            "Purchase Orders: ${authenticate.stats?.openPurOrders ?? 0}",
            "Suppliers: ${authenticate.stats?.suppliers ?? 0}",
          ),
          makeDashboardItem(
            'dbInventory',
            context,
            menuOptions[4],
            "Incoming Shipments: ${authenticate.stats?.incomingShipments ?? 0}",
            "Outgoing Shipments: ${authenticate.stats?.outgoingShipments ?? 0}",
            "Wh Locations: ${authenticate.stats?.whLocations ?? 0}",
            "",
          ),
          makeDashboardItem(
            'dbAccounting',
            context,
            menuOptions[5],
            "Sales open invoices: \n"
                "${authenticate.company!.currency?.currencyId} "
                "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                "(${authenticate.stats?.salesInvoicesNotPaidCount ?? 0})",
            "Purchase unpaid invoices: \n"
                "${authenticate.company!.currency?.currencyId} "
                "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                "(${authenticate.stats?.purchInvoicesNotPaidCount ?? 0})",
            "",
            "",
          ),
        ]);
      }
      return const LoadingIndicator();
    });
  }
}
