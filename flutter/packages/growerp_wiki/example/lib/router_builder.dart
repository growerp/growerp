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
