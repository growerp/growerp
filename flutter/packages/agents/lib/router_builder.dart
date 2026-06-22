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
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';

/// Local fallback menu for the Agents app (mirrors the AGENTS_DEFAULT backend
/// seed). The dynamic router normally renders the backend menu so options can
/// be reordered / minimized per user; this is used by integration tests.
const agentsMenuConfig = MenuConfiguration(
  menuConfigurationId: 'AGENTS_DEFAULT',
  appId: 'agents',
  name: 'Agents Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'AGENTS_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'AgentsDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_AICHAT',
      title: 'AI Chat',
      route: '/chat',
      iconName: 'smart_toy',
      sequenceNum: 20,
      widgetName: 'AdkChatView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_AIAGENTS',
      title: 'AI Agents',
      route: '/adk-agents',
      iconName: 'smart_toy',
      sequenceNum: 30,
      widgetName: 'AdkAgentListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_MCPSERVERS',
      title: 'Tools & integrations',
      route: '/adk-mcp-servers',
      iconName: 'dns',
      sequenceNum: 35,
      widgetName: 'AdkMcpServerListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_AIJOBS',
      title: 'Agent Jobs',
      route: '/adk-jobs',
      iconName: 'schedule',
      sequenceNum: 40,
      widgetName: 'AdkJobListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_APPROVALS',
      title: 'Approvals',
      route: '/adk-approvals',
      iconName: 'fact_check',
      sequenceNum: 50,
      widgetName: 'AdkApprovalsListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_ACTIONS',
      title: 'Agent Actions',
      route: '/adk-actions',
      iconName: 'history',
      sequenceNum: 60,
      widgetName: 'AdkActionsListView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_KNOWLEDGE',
      title: 'Knowledge',
      route: '/adk-knowledge',
      iconName: 'menu_book',
      sequenceNum: 65,
      widgetName: 'AdkKnowledgeView',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'AGENTS_ORG',
      title: 'Organization',
      route: '/organization',
      iconName: 'business',
      sequenceNum: 70,
      widgetName: 'ShowCompanyDialog',
      isActive: true,
      children: [
        MenuItem(
          menuItemId: 'AGENTS_ORG_COMPANY',
          title: 'company',
          iconName: 'home',
          widgetName: 'ShowCompanyDialog',
          sequenceNum: 10,
        ),
        MenuItem(
          menuItemId: 'AGENTS_ORG_USERS',
          title: 'employees',
          iconName: 'school',
          widgetName: 'UserListEmployee',
          sequenceNum: 20,
        ),
        MenuItem(
          menuItemId: 'AGENTS_ORG_WEB',
          title: 'Web',
          iconName: 'webhook',
          widgetName: 'WebsiteDialog',
          sequenceNum: 30,
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'AGENTS_SETUP',
      title: 'System Setup',
      route: '/setup',
      iconName: 'settings',
      sequenceNum: 80,
      widgetName: 'SystemSetupDialog',
      isActive: true,
    ),
  ],
);

/// Create the dynamic router for the Agents app (renders the backend menu).
GoRouter createDynamicAgentsRouter(
  List<MenuConfiguration> configurations, {
  GlobalKey<NavigatorState>? rootNavigatorKey,
  MenuConfigBloc? menuConfigBloc,
}) {
  for (final widgets in agentsWidgetRegistrations) {
    WidgetRegistry.register(widgets);
  }

  return createDynamicAppRouter(
    configurations,
    rootNavigatorKey: rootNavigatorKey,
    config: DynamicRouterConfig(
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Agents',
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

/// Widget registrations for the Agents app: building-block widgets plus the
/// app-specific dashboard and ADK governance views.
List<Map<String, GrowerpWidgetBuilder>> agentsWidgetRegistrations = [
  getUserCompanyWidgets(),
  getWebsiteWidgets(),
  {
    'AgentsDashboard': (args) => const AgentsDashboard(),
    'AboutForm': (args) => const AboutForm(),
    'SystemSetupDialog': (args) => const SystemSetupDialog(),
    'AdkAgentListView': (args) => const AdkAgentListView(),
    'AdkMcpServerListView': (args) => const AdkMcpServerListView(),
    'AdkJobListView': (args) => const AdkJobListView(),
    'AdkApprovalsListView': (args) => const AdkApprovalsListView(),
    'AdkActionsListView': (args) => const AdkActionsListView(),
    'AdkKnowledgeView': (args) => const AdkKnowledgeView(),
    'AdkChatView': (args) => AdkChatView(
          menuItems: agentsMenuConfig.menuItems
              .where((m) => m.isActive && m.route != null)
              .map((m) => ChatMenuEntry(title: m.title, route: m.route!))
              .toList(),
        ),
  },
];

/// Dashboard for the Agents app. Built from the live MenuConfigBloc menu so
/// dashboard tiles can be long-press reordered and minimized — those actions
/// are persisted back to the menu configuration (same pattern as the admin app).
class AgentsDashboard extends StatelessWidget {
  const AgentsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;
        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;
            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }
            // Top-level active items shown as dashboard tiles (skip root/about).
            final dashboardOptions = menuConfig.menuItems
                .where((o) =>
                    o.isActive &&
                    o.route != null &&
                    o.route != '/' &&
                    o.route != '/about')
                .toList()
              ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: DashboardGrid(
                items: dashboardOptions,
                stats: stats,
                onToggleMinimize: (id) => context
                    .read<MenuConfigBloc>()
                    .add(MenuItemToggleMinimize(id)),
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthLoad());
                },
              ),
            );
          },
        );
      },
    );
  }
}
