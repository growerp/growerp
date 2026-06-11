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
import 'package:growerp_adk/growerp_adk.dart';

/// Canonical (static) menu configuration for the standalone ADK app.
/// Used by both the production app (main.dart) and integration tests — no
/// backend-seeded menu required.
const adkMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADK_EXAMPLE',
  appId: 'adk_example',
  name: 'ADK App Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'ADK_MAIN',
      itemKey: 'ADK_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'AdkDashboard',
    ),
    MenuItem(
      menuItemId: 'ADK_CHAT',
      itemKey: 'ADK_CHAT',
      title: 'AI Chat',
      route: '/chat',
      iconName: 'smart_toy',
      sequenceNum: 20,
      widgetName: 'AdkChatView',
    ),
    MenuItem(
      menuItemId: 'ADK_AGENTS',
      itemKey: 'ADK_AGENTS',
      title: 'AI Agents',
      route: '/adk-agents',
      iconName: 'smart_toy',
      sequenceNum: 30,
      widgetName: 'AdkAgentListView',
    ),
    MenuItem(
      menuItemId: 'ADK_JOBS',
      itemKey: 'ADK_JOBS',
      title: 'Agent Jobs',
      route: '/adk-jobs',
      iconName: 'schedule',
      sequenceNum: 40,
      widgetName: 'AdkJobListView',
    ),
    MenuItem(
      menuItemId: 'ADK_APPROVALS',
      itemKey: 'ADK_APPROVALS',
      title: 'Approvals',
      route: '/adk-approvals',
      iconName: 'fact_check',
      sequenceNum: 50,
      widgetName: 'AdkApprovalsListView',
    ),
    MenuItem(
      menuItemId: 'ADK_ACTIONS',
      itemKey: 'ADK_ACTIONS',
      title: 'Agent Actions',
      route: '/adk-actions',
      iconName: 'history',
      sequenceNum: 60,
      widgetName: 'AdkActionsListView',
    ),
  ],
);

/// Chat navigation entries derived from the menu (so the AI chat can open
/// the same screens by name).
List<ChatMenuEntry> _chatEntries() => adkMenuConfig.menuItems
    .where((m) => m.route != null && m.route != '/chat')
    .map((m) => ChatMenuEntry(title: m.title, route: m.route!))
    .toList();

/// Maps a route to its screen widget.
Widget _routeWidget(String route) => switch (route) {
      '/chat' => AdkChatView(menuItems: _chatEntries()),
      '/adk-agents' => const AdkAgentListView(),
      '/adk-jobs' => const AdkJobListView(),
      '/adk-approvals' => const AdkApprovalsListView(),
      '/adk-actions' => const AdkActionsListView(),
      _ => const AdkDashboard(),
    };

/// Creates the static go_router for the standalone ADK app.
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createAdkExampleRouter() {
  return createStaticAppRouter(
    menuConfig: adkMenuConfig,
    appTitle: 'GrowERP ADK',
    dashboard: const AdkDashboard(),
    widgetBuilder: _routeWidget,
    mainRouteActions: [
      Builder(
        builder: (ctx) => IconButton(
          key: const Key('adkChatFab'),
          tooltip: 'AI Assistant',
          icon: const Icon(Icons.smart_toy),
          onPressed: () => AdkChatDialog.show(ctx),
        ),
      ),
    ],
  );
}

/// Dashboard for the standalone ADK app.
class AdkDashboard extends StatelessWidget {
  const AdkDashboard({super.key});

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
              menuItemId: 'chat',
              title: 'AI Chat',
              iconName: 'smart_toy',
              route: '/chat',
            ),
            MenuItem(
              menuItemId: 'agents',
              title: 'AI Agents',
              iconName: 'smart_toy',
              route: '/adk-agents',
            ),
            MenuItem(
              menuItemId: 'jobs',
              title: 'Agent Jobs',
              iconName: 'schedule',
              route: '/adk-jobs',
            ),
            MenuItem(
              menuItemId: 'approvals',
              title: 'Approvals',
              iconName: 'fact_check',
              route: '/adk-approvals',
            ),
            MenuItem(
              menuItemId: 'actions',
              title: 'Agent Actions',
              iconName: 'history',
              route: '/adk-actions',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
