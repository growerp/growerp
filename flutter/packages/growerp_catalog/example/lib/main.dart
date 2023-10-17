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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  runApp(TopApp(
    classificationId: 'AppAdmin',
    dbServer: APIRepository(),
    chatServer: ChatServer(),
    title: 'GrowERP Package Inventory.',
    router: generateRoute,
    menuOptions: menuOptions,
    extraDelegates: const [CatalogLocalizations.delegate],
    restClient: RestClient(await buildDioClient('http://localhost:8080/')),
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
      image: 'packages/growerp_core/images/productsGrey.png',
      selectedImage: 'packages/growerp_core/images/products.png',
      title: 'Catalog',
      route: '/catalog',
      readGroups: [
        UserGroup.admin,
        UserGroup.employee
      ],
      writeGroups: [
        UserGroup.admin
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
          label: 'Catgs',
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
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/user':
      return MaterialPageRoute(
          builder: (context) => HomeForm(menuOptions: menuOptions));
    case '/catalog':
      return MaterialPageRoute(
          builder: (context) => DisplayMenuOption(
              menuList: menuOptions, menuIndex: 1, tabIndex: 0));
    default:
      return MaterialPageRoute(
          builder: (context) => FatalErrorForm(
              message: "Routing not found for request: ${settings.name}"));
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
          makeDashboardItem('dbCatalog', context, menuOptions[1], [
            "Categories: ${authenticate.stats?.categories ?? 0}",
            "Products: ${authenticate.stats?.products ?? 0}",
            "Assets: ${authenticate.stats?.assets ?? 0}",
          ]),
        ]);
      }

      return const LoadingIndicator();
    });
  }
}
