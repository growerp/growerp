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
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for Activity example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const activityMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ACTIVITY_EXAMPLE',
  appId: 'activity_example',
  name: 'Activity Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'ACT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'ActivityDashboard',
    ),
    MenuItem(
      itemKey: 'ACT_TODO',
      title: 'To Do',
      route: '/todos',
      iconName: 'check_circle',
      sequenceNum: 20,
      widgetName: 'ActivityList',
    ),
    MenuItem(
      itemKey: 'ACT_EVENTS',
      title: 'Events',
      route: '/events',
      iconName: 'event',
      sequenceNum: 30,
      widgetName: 'ActivityList',
    ),
  ],
);

/// Creates a static go_router for the activity example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createActivityExampleRouter() {
  return createStaticAppRouter(
    menuConfig: activityMenuConfig,
    appTitle: 'GrowERP Activity Example',
    dashboard: const ActivityDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/todos' => const ActivityList(ActivityType.todo),
      '/events' => const ActivityList(ActivityType.event),
      _ => const ActivityDashboard(),
    },
  );
}

/// BLoC providers for the activity example app.
///
/// Used by both the production app (main.dart) and all integration tests.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getActivityBlocProviders(restClient, classificationId),
    ...getUserCompanyBlocProviders(restClient, classificationId),
  ];
}

/// Localizations delegates for the activity example app.
List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  ActivityLocalizations.delegate,
  UserCompanyLocalizations.delegate,
];

/// Simple dashboard for activity example
class ActivityDashboard extends StatelessWidget {
  const ActivityDashboard({super.key});

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
              menuItemId: 'todos',
              title: 'To Do',
              iconName: 'check_circle',
              route: '/todos',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'events',
              title: 'Events',
              iconName: 'event',
              route: '/events',
              tileType: 'statistic',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
