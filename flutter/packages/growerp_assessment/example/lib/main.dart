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
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:growerp_models/growerp_models.dart';

// Export for integration tests
export 'package:growerp_core/growerp_core.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');
  String classificationId = GlobalConfiguration().get("classificationId");

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: classificationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Assessment & Landing Page Management',
      router: generateRoute,
      menuOptions: (context) => menuOptions(context),
      extraDelegates: const [],
      extraBlocProviders: getExampleBlocProviders(restClient, classificationId),
    ),
  );
}

List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [...getAssessmentBlocProviders(restClient, classificationId)];
}

// Menu definition
List<MenuOption> menuOptions(BuildContext context) => [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const MainMenu(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/categoriesGrey.png',
    selectedImage: 'packages/growerp_core/images/categories.png',
    title: 'Landing Pages',
    route: '/landingPages',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const LandingPageList(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/orderGrey.png',
    selectedImage: 'packages/growerp_core/images/order.png',
    title: 'Assessments',
    route: '/assessments',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const AssessmentList(),
  ),
];

// Routing
Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint(
    '>>>NavigateTo { ${settings.name} '
    'with: ${settings.arguments} }',
  );

  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => const HomeForm(menuOptions: menuOptions),
      );
    case '/landingPages':
      return MaterialPageRoute(
        builder: (context) =>
            DisplayMenuOption(menuList: menuOptions(context), menuIndex: 1),
      );
    case '/assessments':
      return MaterialPageRoute(
        builder: (context) =>
            DisplayMenuOption(menuList: menuOptions(context), menuIndex: 2),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => FatalErrorForm(
          message: "Routing not found for request: ${settings.name}",
        ),
      );
  }
}

// Main menu with dashboard
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final options = menuOptions(context);
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbLandingPages', context, options[1], [
                'Landing Pages',
                'Create and manage landing pages',
                'Configure hooks and CTAs',
              ]),
              makeDashboardItem('dbAssessments', context, options[2], [
                'Assessments',
                'Create and manage assessments',
                'Define questions and scoring',
              ]),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
  }
}
