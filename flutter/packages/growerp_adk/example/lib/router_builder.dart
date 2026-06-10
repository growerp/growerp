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
import 'package:growerp_adk/growerp_adk.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for the standalone ADK app.
/// Used by both the production app (main.dart) and integration tests.
const adkMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADK_EXAMPLE',
  appId: 'adk_example',
  name: 'ADK App Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'ADK_CHAT',
      title: 'AI Chat',
      route: '/',
      iconName: 'smart_toy',
      sequenceNum: 10,
      widgetName: 'AdkChatView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'ADK_AGENTS',
      title: 'AI Agents',
      route: '/adk-agents',
      iconName: 'smart_toy',
      sequenceNum: 20,
      widgetName: 'AdkAgentListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'ADK_JOBS',
      title: 'Agent Jobs',
      route: '/adk-jobs',
      iconName: 'schedule',
      sequenceNum: 30,
      widgetName: 'AdkJobListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'ADK_APPROVALS',
      title: 'Approvals',
      route: '/adk-approvals',
      iconName: 'fact_check',
      sequenceNum: 40,
      widgetName: 'AdkApprovalsListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'ADK_ACTIONS',
      title: 'Agent Actions',
      route: '/adk-actions',
      iconName: 'history',
      sequenceNum: 50,
      widgetName: 'AdkActionsListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'ADK_COMPANY',
      title: 'Organization',
      route: '/company',
      iconName: 'business',
      sequenceNum: 60,
      widgetName: 'AdkAgentListView',
      isActive: true,
    ),
  ],
);

/// Create the dynamic router for the standalone ADK app.
GoRouter createDynamicAdkRouter(
  List<MenuConfiguration> configurations, {
  GlobalKey<NavigatorState>? rootNavigatorKey,
  MenuConfigBloc? menuConfigBloc,
}) {
  for (final widgets in adkWidgetRegistrations) {
    WidgetRegistry.register(widgets);
  }

  return createDynamicAppRouter(
    configurations,
    rootNavigatorKey: rootNavigatorKey,
    config: DynamicRouterConfig(
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP ADK',
      dashboardFabBuilder: (_) => Builder(
        builder: (ctx) => FloatingActionButton(
          key: const Key('adkChatFab'),
          tooltip: 'AI Assistant',
          onPressed: () => AdkChatDialog.show(ctx),
          child: const Icon(Icons.smart_toy),
        ),
      ),
    ),
  );
}

/// Widget registrations for the standalone ADK app.
List<Map<String, GrowerpWidgetBuilder>> adkWidgetRegistrations = [
  getUserCompanyWidgets(),
  {
    'AboutForm': (args) => const AboutForm(),
    'SystemSetupDialog': (args) => const SystemSetupDialog(),
    'AdkAgentListView': (args) => const AdkAgentListView(),
    'AdkJobListView': (args) => const AdkJobListView(),
    'AdkApprovalsListView': (args) => const AdkApprovalsListView(),
    'AdkActionsListView': (args) => const AdkActionsListView(),
    'AdkChatView': (args) {
      final routeDialogBuilders = <String, WidgetBuilder>{
        '/company': (ctx) => ShowCompanyDialog(
              ctx.read<AuthBloc>().state.authenticate?.company ?? Company(),
              dialog: true,
            ),
      };
      return AdkChatView(
        menuItems: adkMenuConfig.menuItems
            .where((m) => m.isActive && m.route != null)
            .map((m) => ChatMenuEntry(
                  title: m.title,
                  route: m.route!,
                  dialogBuilder: routeDialogBuilders[m.route],
                ))
            .toList(),
      );
    },
  },
];
