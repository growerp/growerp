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
import 'package:growerp_models/growerp_models.dart';
import '../../growerp_core.dart';

/// Configuration for creating a static app router for example apps.
///
/// This is a simplified version of [DynamicRouterConfig] designed for
/// example apps that use static [MenuConfiguration] (not fetched from backend).
class StaticRouterConfig {
  /// The static menu configuration
  final MenuConfiguration menuConfig;

  /// The app title shown in login screen
  final String appTitle;

  /// Function to build widget for a given route
  /// The route string matches [MenuOption.route]
  final Widget Function(String route) widgetBuilder;

  /// Optional dashboard widget for the main '/' route
  /// If null, uses widgetBuilder('/')
  final Widget? dashboard;

  /// Additional routes not defined in menuConfig
  /// These will be added inside the ShellRoute
  final List<RouteBase> additionalRoutes;

  /// Optional actions for the main route (e.g., logout button)
  /// If null, adds a default logout button
  final List<Widget>? mainRouteActions;

  const StaticRouterConfig({
    required this.menuConfig,
    required this.appTitle,
    required this.widgetBuilder,
    this.dashboard,
    this.additionalRoutes = const [],
    this.mainRouteActions,
  });
}

/// Creates a static GoRouter for example apps.
///
/// This encapsulates the common router pattern:
/// - Auth redirect to '/' when not authenticated
/// - Main route with logout button
/// - ShellRoute for sub-routes without logout button
///
/// Usage:
/// ```dart
/// final router = createStaticAppRouter(
///   menuConfig: myMenuConfig,
///   appTitle: 'My App',
///   widgetBuilder: (route) => switch (route) {
///     '/products' => const ProductList(),
///     '/categories' => const CategoryList(),
///     _ => const Dashboard(),
///   },
///   dashboard: const MyDashboard(),
/// );
/// ```
GoRouter createStaticAppRouter({
  required MenuConfiguration menuConfig,
  required String appTitle,
  required Widget Function(String route) widgetBuilder,
  Widget? dashboard,
  List<RouteBase> additionalRoutes = const [],
  List<Widget>? mainRouteActions,
}) {
  final config = StaticRouterConfig(
    menuConfig: menuConfig,
    appTitle: appTitle,
    widgetBuilder: widgetBuilder,
    dashboard: dashboard,
    additionalRoutes: additionalRoutes,
    mainRouteActions: mainRouteActions,
  );

  return _buildStaticRouter(config);
}

GoRouter _buildStaticRouter(StaticRouterConfig config) {
  // Get dashboard widget
  Widget getDashboard() {
    return config.dashboard ?? config.widgetBuilder('/');
  }

  // Build default logout action
  List<Widget> getMainActions(BuildContext context) {
    if (config.mainRouteActions != null) {
      return config.mainRouteActions!;
    }
    return [
      IconButton(
        key: const Key('logoutButton'),
        icon: const Icon(Icons.do_not_disturb),
        tooltip: 'Logout',
        onPressed: () {
          context.read<AuthBloc>().add(const AuthLoggedOut());
        },
      ),
    ];
  }

  // Generate routes from menu config (excluding '/')
  List<RouteBase> generateRoutes() {
    final routes = <RouteBase>[];
    final processedPaths = <String>{};

    for (final option in config.menuConfig.menuOptions) {
      if (option.route == null ||
          option.route == '/' ||
          option.route!.isEmpty) {
        continue;
      }
      if (processedPaths.contains(option.route)) continue;
      processedPaths.add(option.route!);

      final route = option.route!;
      // Use widgetName from MenuOption as the key for test discoverability
      final widgetKey = option.widgetName ?? option.itemKey;

      routes.add(
        GoRoute(
          path: route,
          builder: (context, state) {
            final widget = config.widgetBuilder(route);
            // Wrap with KeyedSubtree if a key name is available
            if (widgetKey != null) {
              return KeyedSubtree(key: Key(widgetKey), child: widget);
            }
            return widget;
          },
        ),
      );
    }

    // Add any additional routes
    routes.addAll(config.additionalRoutes);

    return routes;
  }

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      if (!isAuthenticated && state.uri.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      // Root route - shows home form or dashboard
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return DisplayMenuOption(
              menuConfiguration: config.menuConfig,
              menuIndex: 0,
              actions: getMainActions(context),
              child: getDashboard(),
            );
          } else {
            return HomeForm(
              menuConfiguration: config.menuConfig,
              title: config.appTitle,
            );
          }
        },
      ),
      // Shell route for sub-routes with consistent menu
      if (generateRoutes().isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < config.menuConfig.menuOptions.length; i++) {
              if (config.menuConfig.menuOptions[i].route == path) {
                menuIndex = i;
                break;
              }
            }
            return DisplayMenuOption(
              menuConfiguration: config.menuConfig,
              menuIndex: menuIndex,
              child: child,
            );
          },
          routes: generateRoutes(),
        ),
    ],
  );
}
