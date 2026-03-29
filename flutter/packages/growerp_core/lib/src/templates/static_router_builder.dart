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
  /// The route string matches [MenuItem.route]
  final Widget Function(String route) widgetBuilder;

  /// Optional dashboard widget for the main '/' route
  /// If null, uses widgetBuilder('/')
  final Widget? dashboard;

  /// Additional routes not defined in menuConfig that need the shell
  /// (nav rail / drawer) wrapper. These are added inside the ShellRoute so
  /// the navigation UI remains visible while viewing them.
  final List<RouteBase> shellRoutes;

  /// Additional routes that are added at the top level (outside the ShellRoute).
  /// Use this for dialog-style full-screen routes (e.g. /findoc, /printer)
  /// that should not show the nav rail / drawer.
  final List<RouteBase> additionalRoutes;

  /// Optional actions for the main route (e.g., logout button)
  /// If null, adds a default logout button
  final List<Widget>? mainRouteActions;

  /// Optional function to load tab widgets by widgetName
  /// Used when MenuItems have children (tabs)
  final Widget Function(String widgetName, Map<String, dynamic> args)?
  tabWidgetLoader;

  const StaticRouterConfig({
    required this.menuConfig,
    required this.appTitle,
    required this.widgetBuilder,
    this.dashboard,
    this.shellRoutes = const [],
    this.additionalRoutes = const [],
    this.mainRouteActions,
    this.tabWidgetLoader,
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
  List<RouteBase> shellRoutes = const [],
  List<RouteBase> additionalRoutes = const [],
  List<Widget>? mainRouteActions,
  Widget Function(String widgetName, Map<String, dynamic> args)?
  tabWidgetLoader,
}) {
  final config = StaticRouterConfig(
    menuConfig: menuConfig,
    appTitle: appTitle,
    widgetBuilder: widgetBuilder,
    dashboard: dashboard,
    shellRoutes: shellRoutes,
    additionalRoutes: additionalRoutes,
    mainRouteActions: mainRouteActions,
    tabWidgetLoader: tabWidgetLoader,
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

    for (final option in config.menuConfig.menuItems) {
      if (option.route == null ||
          option.route == '/' ||
          option.route!.isEmpty) {
        continue;
      }
      if (processedPaths.contains(option.route)) continue;
      processedPaths.add(option.route!);

      final route = option.route!;
      // Use widgetName from MenuItem as the key for test discoverability
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
            return DisplayMenuItem(
              menuConfiguration: config.menuConfig,
              menuIndex: 0,
              actions: getMainActions(context),
              tabWidgetLoader: config.tabWidgetLoader,
              suppressBlocMenuConfig: true,
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
      if (generateRoutes().isNotEmpty || config.shellRoutes.isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            int menuIndex = 0;
            final path = state.uri.path;
            // First try exact match, then longest-prefix match so that
            // sub-routes like /accounting/purchase correctly highlight the
            // parent /accounting nav-rail item.
            int bestPrefixLength = 0;
            for (int i = 0; i < config.menuConfig.menuItems.length; i++) {
              final route = config.menuConfig.menuItems[i].route;
              if (route == null || route == '/') continue;
              if (route == path) {
                menuIndex = i;
                break;
              }
              if (path.startsWith(route) && route.length > bestPrefixLength) {
                bestPrefixLength = route.length;
                menuIndex = i;
              }
            }
            return DisplayMenuItem(
              menuConfiguration: config.menuConfig,
              menuIndex: menuIndex,
              tabWidgetLoader: config.tabWidgetLoader,
              suppressBlocMenuConfig: true,
              child: child,
            );
          },
          routes: [...generateRoutes(), ...config.shellRoutes],
        ),
      // User profile route - full screen, no shell wrapper
      GoRoute(
        path: '/user',
        builder: (context, state) {
          final extra = state.extra;
          return WidgetRegistry.getWidget('UserDialog', {'user': extra});
        },
      ),

      // Company dialog route - full screen, no shell wrapper
      GoRoute(
        path: '/company',
        builder: (context, state) {
          final extra = state.extra;
          return WidgetRegistry.getWidget('ShowCompanyDialog', {
            'company': extra,
          });
        },
      ),

      // Top-level routes without the shell wrapper (e.g. dialog-style screens)
      ...config.additionalRoutes,
    ],
  );
}
