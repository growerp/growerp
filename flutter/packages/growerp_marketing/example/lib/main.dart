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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
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
      title: 'GrowERP Marketing Example',
      router: createMarketingExampleRouter(),
      extraDelegates: const [],
      extraBlocProviders: getExampleBlocProviders(restClient, classificationId),
    ),
  );
}

List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [...getMarketingBlocProviders(restClient, classificationId)];
}

/// Static menu configuration
const marketingMenuConfig = MenuConfiguration(
  menuConfigurationId: 'MARKETING_EXAMPLE',
  appId: 'marketing_example',
  name: 'Marketing Example Menu',
  menuOptions: [
    MenuOption(
      itemKey: 'MKT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuOption(
      itemKey: 'MKT_LANDING',
      title: 'Landing Pages',
      route: '/landingPages',
      iconName: 'web',
      sequenceNum: 20,
    ),
    MenuOption(
      itemKey: 'MKT_ASSESSMENTS',
      title: 'Assessments',
      route: '/assessments',
      iconName: 'quiz',
      sequenceNum: 30,
    ),
    MenuOption(
      itemKey: 'MKT_TAKE',
      title: 'Take Assessment',
      route: '/takeAssessment',
      iconName: 'assignment',
      sequenceNum: 40,
    ),
    MenuOption(
      itemKey: 'MKT_PERSONAS',
      title: 'Personas',
      route: '/personas',
      iconName: 'people',
      sequenceNum: 50,
    ),
    MenuOption(
      itemKey: 'MKT_CONTENT',
      title: 'Content Plans',
      route: '/contentPlans',
      iconName: 'calendar_today',
      sequenceNum: 60,
    ),
    MenuOption(
      itemKey: 'MKT_SOCIAL',
      title: 'Social Posts',
      route: '/socialPosts',
      iconName: 'share',
      sequenceNum: 70,
    ),
  ],
);

/// Creates a static go_router for the marketing example app
GoRouter createMarketingExampleRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      if (!isAuthenticated && state.uri.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return const DisplayMenuOption(
              menuConfiguration: marketingMenuConfig,
              menuIndex: 0,
              child: MarketingDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: marketingMenuConfig,
              title: 'GrowERP Marketing Example',
            );
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (int i = 0; i < marketingMenuConfig.menuOptions.length; i++) {
            final route = marketingMenuConfig.menuOptions[i].route;
            if (route != null &&
                (route == path ||
                    (route != '/' && path.startsWith('$route/')))) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: marketingMenuConfig,
            menuIndex: menuIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/landingPages',
            builder: (context, state) => const LandingPageList(),
          ),
          GoRoute(
            path: '/assessments',
            builder: (context, state) => const AssessmentList(),
          ),
          GoRoute(
            path: '/takeAssessment',
            builder: (context, state) => const TakeAssessmentMenu(),
            routes: [
              GoRoute(
                path: 'flow',
                builder: (context, state) => LandingPageAssessmentFlowScreen(
                  landingPageId:
                      state.uri.queryParameters['landingPageId'] ?? '',
                  assessmentId: state.uri.queryParameters['assessmentId'] ?? '',
                  startAssessmentFlow: true,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/personas',
            builder: (context, state) => const PersonaList(),
          ),
          GoRoute(
            path: '/contentPlans',
            builder: (context, state) => const ContentPlanList(),
          ),
          GoRoute(
            path: '/socialPosts',
            builder: (context, state) => const SocialPostList(),
          ),
        ],
      ),
    ],
  );
}

/// Simple dashboard for marketing example
class MarketingDashboard extends StatelessWidget {
  const MarketingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final items = marketingMenuConfig.menuOptions
            .where((item) => item.route != '/')
            .toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DashboardCard(
                title: item.title,
                iconName: item.iconName ?? 'dashboard',
                route: item.route ?? '/',
              );
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Take Assessment menu - allows selecting and taking an assessment
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
                    context.go(
                      Uri(
                        path: '/takeAssessment/flow',
                        queryParameters: {
                          'landingPageId': assessment.pseudoId ?? '',
                          'assessmentId': assessment.assessmentId ?? '',
                        },
                      ).toString(),
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
