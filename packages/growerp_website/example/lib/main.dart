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

import 'package:flutter/foundation.dart';
import 'package:growerp_core/domains/domains.dart';
import 'package:growerp_core/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/services/chat_server.dart';
import 'package:growerp_core/templates/displayMenuOption.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:growerp_website/growerp_website.dart';

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
    image: 'assets/images/dashBoardGrey.png',
    selectedImage: 'assets/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    child: const MainMenuForm(),
  ),
  MenuOption(
    image: 'assets/images/companyGrey.png',
    selectedImage: 'assets/images/company.png',
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
    image: 'assets/images/crmGrey.png',
    selectedImage: 'assets/images/crm.png',
    title: 'Website',
    route: '/website',
    readGroups: [UserGroup.Admin, UserGroup.Employee, UserGroup.SuperAdmin],
    writeGroups: [UserGroup.Admin, UserGroup.SuperAdmin],
    child: const WebsiteForm(),
  ),
  MenuOption(
      image: 'assets/images/productsGrey.png',
      selectedImage: 'assets/images/products.png',
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
          form: ProductListForm(),
          label: 'Products',
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: AssetListForm(),
          label: 'Assets',
          icon: const Icon(Icons.money),
        ),
        TabItem(
          form: CategoryListForm(),
          label: 'Categories',
          icon: const Icon(Icons.business),
        ),
      ]),
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
    case '/website':
      return MaterialPageRoute(
          builder: (context) =>
              DisplayMenuOption(menuList: menuOptions, menuIndex: 2));
    case '/catalog':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 3, tabIndex: 0));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              "Routing not found for request: ${settings.name}"));
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
            'dbWebsite',
            context,
            menuOptions[2],
            "",
            "",
            "",
            "",
          ),
          makeDashboardItem(
            'dbCatalog',
            context,
            menuOptions[3],
            "Categories: ${authenticate.stats?.categories ?? 0}",
            "Products: ${authenticate.stats?.products ?? 0}",
            "Assets: ${authenticate.stats?.assets ?? 0}",
            "",
          ),
        ]);
      }

      return LoadingIndicator();
    });
  }
}
