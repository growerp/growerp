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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'views/core_dashboard.dart';

/// Create the dynamic router for Core example app
///
/// This is used by integration tests to create a router with test configurations.
GoRouter createDynamicCoreRouter(
  List<MenuConfiguration> configurations, {
  GlobalKey<NavigatorState>? rootNavigatorKey,
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
