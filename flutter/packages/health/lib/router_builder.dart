/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'widget_registry.dart';
import 'views/main_menu_form.dart';

/// Builds a GoRouter dynamically from a list of MenuConfigurations for the Health app
GoRouter createDynamicHealthRouter(
  List<MenuConfiguration> configurations, {
  String initialLocation = '/',
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  // Find Health main config
  final healthConfig = configurations.firstWhere(
    (c) => c.menuConfigurationId == 'HEALTH_DEFAULT',
    orElse: () => configurations.isNotEmpty
        ? configurations.first
        : const MenuConfiguration(
            menuOptions: [],
            appId: 'health',
            name: 'Health',
          ),
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: (context, state) {
      // Authentication check
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated && state.uri.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      // Root '/'
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return DisplayMenuOption(
              menuConfiguration: healthConfig,
              menuIndex: 0,
              actions: [
                IconButton(
                  key: const Key('logoutButton'),
                  icon: const Icon(Icons.do_not_disturb),
                  tooltip: 'Logout',
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              child: const AdminDbForm(),
            );
          } else {
            return HomeForm(
              menuConfiguration: healthConfig,
              title: 'GrowERP Health',
            );
          }
        },
      ),

      // Health Shell - only add if there are routes
      if (_generateRoutes(healthConfig).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            // Calculate menu index
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < healthConfig.menuOptions.length; i++) {
              if (healthConfig.menuOptions[i].route == path) {
                menuIndex = i;
                break;
              }
            }
            return DisplayMenuOption(
              menuConfiguration: healthConfig,
              menuIndex: menuIndex,
              actions: [
                IconButton(
                  key: const Key('logoutButton'),
                  icon: const Icon(Icons.do_not_disturb),
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              child: child,
            );
          },
          routes: _generateRoutes(healthConfig),
        ),
    ],
  );
}

List<RouteBase> _generateRoutes(
  MenuConfiguration config, {
  String? excludePrefix,
}) {
  List<RouteBase> routes = [];

  // Use a set to avoid duplicate routes
  Set<String> processedPaths = {};

  for (var option in config.menuOptions) {
    // Skip inactive items
    if (!option.isActive) {
      continue;
    }

    if (option.route == null || option.route == '/' || option.route!.isEmpty) {
      continue;
    }

    // Skip routes that start with the excluded prefix
    if (excludePrefix != null && option.route!.startsWith(excludePrefix)) {
      continue;
    }

    if (processedPaths.contains(option.route)) continue;
    processedPaths.add(option.route!);

    routes.add(
      GoRoute(
        path: option.route!,
        builder: (context, state) {
          // Map option to widget
          Map<String, dynamic> args = {};
          if (option.itemKey != null) args['key'] = option.itemKey;

          return WidgetRegistry.getWidget(option.widgetName ?? 'Unknown', args);
        },
      ),
    );
  }
  return routes;
}
