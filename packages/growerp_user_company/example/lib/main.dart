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
import 'package:growerp_user_company/growerp_user_company.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  runApp(TopApp(
      dbServer: APIRepository(),
      chatServer: ChatServer(),
      title: 'GrowERP package: growerp_user_company.',
      router: generateRoute,
      menuOptions: menuOptions));
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
    child: const MainMenu(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: 'Companies',
    route: '/companies',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
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
        form: const CompanyListForm(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyListForm(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyListForm(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyListForm(
          key: Key('All'),
          role: null,
        ),
        label: 'All',
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
    image: 'packages/growerp_core/images/companyGrey.png',
    selectedImage: 'packages/growerp_core/images/company.png',
    title: 'Users',
    route: '/users',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    tabItems: [
      TabItem(
        form: const UserListForm(
          key: Key('Employee'),
          role: Role.company,
        ),
        label: 'Employees',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Lead'),
          role: Role.lead,
        ),
        label: 'Leads',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Customer'),
          role: Role.customer,
        ),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Supplier'),
          role: Role.supplier,
        ),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('Unknown'),
          role: Role.unknown,
        ),
        label: 'Others',
        icon: const Icon(Icons.business),
      ),
      TabItem(
        form: const UserListForm(
          key: Key('All'),
          role: null,
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
          builder: (context) => ShowUserDialog(settings.arguments as User));
    case '/companies':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    case '/users':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 2, tabIndex: 0));
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
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        Authenticate authenticate = state.authenticate!;
        return DashBoardForm(dashboardItems: [
          makeDashboardItem('dbCompanies', context, menuOptions[1], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Customers: ${authenticate.stats != null ? authenticate.stats!.customers : 0}",
            "Leads: ${authenticate.stats != null ? authenticate.stats!.leads : 0}",
            "Suppliers: ${authenticate.stats != null ? authenticate.stats!.suppliers : 0}",
          ]),
          makeDashboardItem('dbPersons', context, menuOptions[2], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "Employees: ${authenticate.company?.employees.length ?? 0}",
            "Customers: ${authenticate.stats != null ? authenticate.stats?.customers ?? 0 : 0}",
            "Leads: ${authenticate.stats != null ? authenticate.stats?.leads ?? 0 : 0}",
            "Suppliers: ${authenticate.stats != null ? authenticate.stats?.suppliers ?? 0 : 0}",
          ]),
        ]);
      }
      return const LoadingIndicator();
    });
  }
}
