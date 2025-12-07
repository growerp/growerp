/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'widget_registry.dart';

/// Builds a GoRouter dynamically from a list of MenuConfigurations
GoRouter createDynamicSupportRouter(
  List<MenuConfiguration> configurations, {
  String initialLocation = '/',
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  // Find Support main config
  final mainConfig = configurations.firstWhere(
    (c) => c.menuConfigurationId == 'SUPPORT_DEFAULT',
    orElse: () => configurations.first,
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: (context, state) {
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
              menuConfiguration: mainConfig,
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
              child: const CompanyList(mainOnly: true, role: Role.unknown),
            );
          } else {
            return HomeForm(menuConfiguration: mainConfig, title: 'Support');
          }
        },
      ),

      // Main Shell
      if (_generateRoutes(mainConfig).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < mainConfig.menuOptions.length; i++) {
              if (mainConfig.menuOptions[i].route == path) {
                menuIndex = i;
                break;
              }
            }
            return DisplayMenuOption(
              menuConfiguration: mainConfig,
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
              tabWidgetLoader: (widgetName, args) =>
                  WidgetRegistry.getWidget(widgetName, args),
            );
          },
          routes: _generateRoutes(mainConfig),
        ),
    ],
  );
}

List<RouteBase> _generateRoutes(MenuConfiguration config) {
  List<RouteBase> routes = [];
  Set<String> processedPaths = {};

  for (var option in config.menuOptions) {
    if (!option.isActive) continue;
    if (option.route == null || option.route == '/' || option.route!.isEmpty) {
      continue;
    }
    if (processedPaths.contains(option.route)) continue;

    processedPaths.add(option.route!);

    routes.add(
      GoRoute(
        path: option.route!,
        builder: (context, state) {
          Map<String, dynamic> args = {};
          if (option.itemKey != null) args['key'] = option.itemKey;
          return WidgetRegistry.getWidget(option.widgetName ?? 'Unknown', args);
        },
      ),
    );
  }
  return routes;
}
