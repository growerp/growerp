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
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:growerp_models/growerp_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Assessment Example',
      router: generateRoute,
      menuOptions: (context) => menuOptions(context),
      extraBlocProviders: getAssessmentBlocProviders(restClient),
    ),
  );
}

/// Menu definition for Assessment example app
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
        image: 'packages/growerp_core/images/companyGrey.png',
        selectedImage: 'packages/growerp_core/images/company.png',
        title: 'Organization',
        route: '/company',
        userGroups: [UserGroup.admin, UserGroup.employee],
        child: const MainMenu(),
      ),
      MenuOption(
        image: 'packages/growerp_core/images/supplierGrey.png',
        selectedImage: 'packages/growerp_core/images/supplier.png',
        title: 'Assessment',
        route: '/assessment',
        userGroups: [UserGroup.admin, UserGroup.employee],
        tabItems: [
          TabItem(
            form: const AssessmentListScreen(),
            label: 'Assessments',
            icon: const Icon(Icons.assignment),
          ),
          TabItem(
            form: const AssessmentTakeScreen(),
            label: 'Take Assessment',
            icon: const Icon(Icons.play_arrow),
          ),
          TabItem(
            form: const AssessmentResultsListScreen(),
            label: 'Results',
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
    ];

/// Route generation for navigation
Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    debugPrint(
      '>>>NavigateTo { ${settings.name} '
      'with: ${settings.arguments.toString()} }',
    );
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => HomeForm(menuOptions: menuOptions),
      );
    case '/company':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions(context),
          menuIndex: 1,
        ),
      );
    case '/user':
      return MaterialPageRoute(
        builder: (context) => HomeForm(menuOptions: menuOptions),
      );
    case '/assessment':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions(context),
          menuIndex: 2,
          tabIndex: 0,
        ),
      );
    case '/assessments':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions(context),
          menuIndex: 2,
          tabIndex: 0,
        ),
      );
    case '/take':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions(context),
          menuIndex: 2,
          tabIndex: 1,
        ),
      );
    case '/results':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions(context),
          menuIndex: 2,
          tabIndex: 2,
        ),
      );
    case '/assessment/detail':
      return MaterialPageRoute(
        builder: (context) => AssessmentDetailScreen(
          assessment: settings.arguments as Assessment,
        ),
      );
    case '/assessment/create':
      return MaterialPageRoute(
        builder: (context) => const AssessmentFormScreen(),
      );
    case '/assessment/edit':
      return MaterialPageRoute(
        builder: (context) => AssessmentFormScreen(
          assessment: settings.arguments as Assessment,
        ),
      );
    case '/assessment/result/detail':
      return MaterialPageRoute(
        builder: (context) => AssessmentResultDetailScreen(
          result: settings.arguments as AssessmentResult,
        ),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => FatalErrorForm(
          message: "Routing not found for request: ${settings.name}",
        ),
      );
  }
}

/// Main menu dashboard for assessment example app
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Authenticate authenticate = state.authenticate!;
          final options = menuOptions(context);
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbCompany', context, options[1], [
                authenticate.company!.name!.length > 20
                    ? "${authenticate.company!.name!.substring(0, 20)}..."
                    : "${authenticate.company!.name}",
                "Email: ${authenticate.company!.email}",
                "Currency: ${authenticate.company!.currency!.description}",
                "Employees: ${authenticate.company!.employees.length}",
              ]),
              makeDashboardItem('dbAssessment', context, options[2], [
                "Assessments: 0",
                "Leads: 0",
                "Results: 0",
              ]),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
  }
}

// AssessmentListScreen and AssessmentResultsListScreen are now imported from growerp_assessment package
