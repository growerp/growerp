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
import 'views/core_dashboard.dart';

/// Canonical menu configuration for Core example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const coreMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CORE_EXAMPLE',
  appId: 'core_example',
  name: 'Core Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'CORE_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'CORE_COMPANY',
      title: 'Organization',
      route: '/company',
      iconName: 'business',
      sequenceNum: 20,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'CORE_USER',
      title: 'Logged in User',
      route: '/user',
      iconName: 'person',
      sequenceNum: 30,
      widgetName: 'CoreDashboard',
      isActive: true,
    ),
  ],
);

/// Create the dynamic router for Core example app
///
/// This is used by integration tests to create a router with test configurations.
/// Pass [menuConfigBloc] to enable the dashboard FAB that opens the menu
/// management dialog (required by the dynamic menu CRUD test).
GoRouter createDynamicCoreRouter(
  List<MenuConfiguration> configurations, {
  GlobalKey<NavigatorState>? rootNavigatorKey,
  MenuConfigBloc? menuConfigBloc,
}) {
  // Register widgets before creating router
  for (final widgets in coreWidgetRegistrations) {
    WidgetRegistry.register(widgets);
  }

  return createDynamicAppRouter(
    configurations,
    rootNavigatorKey: rootNavigatorKey,
    config: DynamicRouterConfig(
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'Core Example',
      dashboardFabBuilder: menuConfigBloc == null
          ? null
          : (menuConfig) => Builder(
                builder: (fabContext) => FloatingActionButton(
                  key: const Key('coreFab'),
                  heroTag: 'menuFab',
                  tooltip: 'Manage Menu Items',
                  onPressed: () {
                    // Use backend-loaded config from bloc when available (has
                    // correct menuConfigurationId); fall back to static config.
                    final currentConfig =
                        menuConfigBloc.state.menuConfiguration ?? menuConfig;
                    showDialog(
                      context: fabContext,
                      builder: (dialogContext) => BlocProvider.value(
                        value: menuConfigBloc,
                        child: MenuItemListDialog(
                          menuConfiguration: currentConfig,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.menu),
                ),
              ),
    ),
  );
}

/// Widget registrations for Core example app
List<Map<String, GrowerpWidgetBuilder>> coreWidgetRegistrations = [
  getUserCompanyWidgets(),
  // App-specific widgets
  {
    'CoreDashboard': (args) => const CoreDashboard(),
    'AboutForm': (args) => const AboutForm(),
    'SystemSetupDialog': (args) => const SystemSetupDialog(),
  },
];
