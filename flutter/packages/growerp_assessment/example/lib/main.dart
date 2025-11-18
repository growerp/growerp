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
      menuOptions: (context) => testMenuOptions,
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

// Test menu options (simplified for integration tests)
List<MenuOption> testMenuOptions = [
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
  MenuOption(
    image: 'packages/growerp_core/images/assessment-grey.png',
    selectedImage: 'packages/growerp_core/images/assessment-color.png',
    title: 'Take Assessment',
    route: '/takeAssessment',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const TakeAssessmentMenu(),
  ),
];

// Menu definition (for compatibility)
List<MenuOption> menuOptions(BuildContext context) => testMenuOptions;

// Routing
Route<dynamic> generateRoute(RouteSettings settings) {
  debugPrint(
    '>>>NavigateTo { ${settings.name} '
    'with: ${settings.arguments} }',
  );

  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => HomeForm(menuOptions: (c) => testMenuOptions),
      );
    case '/landingPages':
      return MaterialPageRoute(
        builder: (context) =>
            DisplayMenuOption(menuList: testMenuOptions, menuIndex: 1),
      );
    case '/assessments':
      return MaterialPageRoute(
        builder: (context) =>
            DisplayMenuOption(menuList: testMenuOptions, menuIndex: 2),
      );
    case '/takeAssessment':
      return MaterialPageRoute(
        builder: (context) =>
            DisplayMenuOption(menuList: testMenuOptions, menuIndex: 3),
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
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbLandingPages', context, testMenuOptions[1], [
                'Landing Pages',
                'Create and manage landing pages',
                'Configure hooks and CTAs',
              ]),
              makeDashboardItem('dbAssessments', context, testMenuOptions[2], [
                'Assessments',
                'Create and manage assessments',
                'Define questions and scoring',
              ]),
              makeDashboardItem(
                'dbTakeAssessment',
                context,
                testMenuOptions[3],
                [
                  'Take Assessment',
                  'Experience the assessment flow',
                  'Test your assessments',
                ],
              ),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
  }
}

// Take Assessment menu - allows selecting and taking an assessment
class TakeAssessmentMenu extends StatelessWidget {
  const TakeAssessmentMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state.status == AssessmentStatus.initial) {
          context.read<AssessmentBloc>().add(
            const AssessmentFetch(refresh: true),
          );
        }

        if (state.status == AssessmentStatus.loading &&
            state.assessments.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        if (state.assessments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assessment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No assessments available',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an assessment first in the Assessments menu',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select an Assessment to Take'),
            backgroundColor: Colors.transparent,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.assessments.length,
            itemBuilder: (context, index) {
              final assessment = state.assessments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.quiz)),
                  title: Text(
                    assessment.assessmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    assessment.description ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to the assessment flow
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LandingPageAssessmentFlowScreen(
                          landingPageId: assessment.pseudoId ?? '',
                          assessmentId: assessment.assessmentId ?? '',
                          startAssessmentFlow: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
