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
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  await Hive.initFlutter();
  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsServer chatServer = WsServer('chat');
  WsServer notificationServer = WsServer('notws');
  String classificationId = GlobalConfiguration().get("classificationId");

  runApp(TopApp(
    restClient: restClient,
    classificationId: classificationId,
    chatServer: chatServer,
    notificationServer: notificationServer,
    title: 'GrowERP package: growerp_user_company.',
    router: generateRoute,
    menuOptions: menuOptions,
    extraDelegates: const [UserCompanyLocalizations.delegate],
    extraBlocProviders:
        getUserCompanyBlocProviders(restClient, classificationId),
  ));
}

// Menu definition
List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const MainMenu(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: 'Companies',
    route: '/companies',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: ShowCompanyDialog(
          Company(role: Role.company),
          key: const Key('CompanyForm'),
          dialog: false,
        ),
        label: 'Company',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyList(
          key: Key('All'),
          role: null,
        ),
        label: 'All',
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/usersGrey.png',
    selectedImage: 'packages/growerp_core/images/users.png',
    title: 'Users',
    route: '/users',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const UserList(
          key: Key('Employee'),
          role: Role.company,
        ),
        label: 'Employees',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserList(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserList(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const UserList(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserList(
          key: Key('All'),
          role: Role.unknown,
        ),
        label: 'All',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/usersGrey.png',
    selectedImage: 'packages/growerp_core/images/users.png',
    title: 'Companies & Users',
    route: '/companiesUsers',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const CompanyUserList(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const CompanyUserList(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const CompanyUserList(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const CompanyUserList(
          key: Key('All'),
          role: Role.unknown,
        ),
        label: 'All',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
];

// routing
Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint('>>>NavigateTo { ${settings.name} '
      'with: ${settings.arguments} }');

  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/company':
      return MaterialPageRoute(
          builder: (context) =>
              ShowCompanyDialog(settings.arguments as Company));
    case '/user':
      return MaterialPageRoute(
          builder: (context) => UserDialog(settings.arguments as User));
    case '/companies':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/users':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
    case '/companiesUsers':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              message: "Routing not found for request: ${settings.name}"));
  }
}

// main menu
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});
  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: DashBoardForm(dashboardItems: [
          makeDashboardItem('dbCompanies', context, menuOptions[1], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Customers: ${authenticate.stats != null ? authenticate.stats!.customers : 0}",
            "Leads: ${authenticate.stats != null ? authenticate.stats!.leads : 0}",
            "Suppliers: ${authenticate.stats != null ? authenticate.stats!.suppliers : 0}",
          ]),
          makeDashboardItem('dbUsers', context, menuOptions[2], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Employees: ${authenticate.company?.employees.length ?? 0}",
            "Customers: ${authenticate.stats != null ? authenticate.stats?.customers ?? 0 : 0}",
            "Leads: ${authenticate.stats != null ? authenticate.stats?.leads ?? 0 : 0}",
            "Suppliers: ${authenticate.stats != null ? authenticate.stats?.suppliers ?? 0 : 0}",
          ]),
          makeDashboardItem('dbCompaniesUsers', context, menuOptions[3], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Customers: ${authenticate.stats != null ? authenticate.stats?.customers ?? 0 : 0}",
            "Leads: ${authenticate.stats != null ? authenticate.stats?.leads ?? 0 : 0}",
            "Suppliers: ${authenticate.stats != null ? authenticate.stats?.suppliers ?? 0 : 0}",
          ])
        ]),
      ),
    ]);
  }
}
