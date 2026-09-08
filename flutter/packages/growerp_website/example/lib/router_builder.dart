/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';

/// Canonical menu configuration for Website example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const websiteMenuConfig = MenuConfiguration(
  menuConfigurationId: 'WEBSITE_EXAMPLE',
  appId: 'website_example',
  name: 'Website Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'WEB_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'WebsiteDashboard',
    ),
    MenuItem(
      itemKey: 'WEB_WEBSITE',
      title: 'Website',
      route: '/website',
      iconName: 'web',
      sequenceNum: 20,
      widgetName: 'WebsiteDialog',
    ),
    MenuItem(
      itemKey: 'WEB_FORMS',
      title: 'Web Forms',
      route: '/webForms',
      iconName: 'dynamic_form',
      sequenceNum: 25,
      widgetName: 'WebsiteFormList',
    ),
    MenuItem(
      itemKey: 'WEB_LANDING',
      title: 'Landing Pages',
      route: '/landingPages',
      iconName: 'web',
      sequenceNum: 30,
      widgetName: 'LandingPageList',
    ),
    MenuItem(
      itemKey: 'WEB_ASSESSMENTS',
      title: 'Assessments',
      route: '/assessments',
      iconName: 'quiz',
      sequenceNum: 40,
      widgetName: 'AssessmentList',
    ),
    MenuItem(
      itemKey: 'WEB_TAKE',
      title: 'Take Assessment',
      route: '/takeAssessment',
      iconName: 'assignment',
      sequenceNum: 50,
      widgetName: 'TakeAssessmentMenu',
    ),
  ],
);

/// Localization delegates for the website example app and its tests.
const List<LocalizationsDelegate> websiteExampleDelegates = [
  WebsiteLocalizations.delegate,
];

/// Creates a static go_router for the website example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createWebsiteExampleRouter() {
  return createStaticAppRouter(
    menuConfig: websiteMenuConfig,
    appTitle: 'GrowERP Website Example',
    dashboard: const WebsiteDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/website' => const WebsiteDialog(),
      '/webForms' => const WebsiteFormList(),
      '/landingPages' => const LandingPageList(),
      '/assessments' => const AssessmentList(),
      '/takeAssessment' => const TakeAssessmentMenu(),
      _ => const WebsiteDashboard(),
    },
    additionalRoutes: [
      GoRoute(
        path: '/takeAssessment/flow',
        builder: (context, state) => LandingPageAssessmentFlowScreen(
          landingPageId: state.uri.queryParameters['landingPageId'] ?? '',
          assessmentId: state.uri.queryParameters['assessmentId'] ?? '',
          startAssessmentFlow: true,
        ),
      ),
    ],
  );
}

/// BLoC providers for the website example app.
///
/// Used by both the production app (main.dart) and all integration tests.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [...getWebsiteBlocProviders(restClient, applicationId)];
}

/// Simple dashboard for website example
class WebsiteDashboard extends StatelessWidget {
  const WebsiteDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final items = websiteMenuConfig.menuItems
            .where((item) => item.route != '/')
            .toList();

        return DashboardGrid(items: items);
      },
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
            title: Text(
              WebsiteLocalizations.of(context)!.selectAnAssessmentToTake,
            ),
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
