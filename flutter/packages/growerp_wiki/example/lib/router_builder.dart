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
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_wiki/growerp_wiki.dart';

/// Canonical menu configuration for the Wiki example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const wikiMenuConfig = MenuConfiguration(
  menuConfigurationId: 'WIKI_EXAMPLE',
  appId: 'wiki_example',
  name: 'Wiki Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'WIKI_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'WikiDashboard',
    ),
    MenuItem(
      itemKey: 'WIKI_PAGES',
      title: 'Wiki',
      route: '/wiki',
      iconName: 'menu_book',
      sequenceNum: 20,
      widgetName: 'WikiList',
    ),
  ],
);

/// Creates a static go_router for the wiki example app using shared helper.
GoRouter createWikiExampleRouter() {
  return createStaticAppRouter(
    menuConfig: wikiMenuConfig,
    appTitle: 'GrowERP Wiki Example',
    dashboard: const WikiDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/wiki' => const WikiList(),
      _ => const WikiDashboard(),
    },
  );
}

/// BLoC providers for the wiki example app.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [...getUserCompanyBlocProviders(restClient, applicationId)];
}

/// Localizations delegates for the wiki example app.
List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
];

/// Simple dashboard for the wiki example
class WikiDashboard extends StatelessWidget {
  const WikiDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }
        return DashboardGrid(
          items: const [
            MenuItem(
              menuItemId: 'wiki',
              title: 'Wiki',
              iconName: 'menu_book',
              route: '/wiki',
              tileType: 'statistic',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
