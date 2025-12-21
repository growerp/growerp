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

/// Configuration for creating a dynamic app router
///
/// Most parameters are optional for simpler apps. Required: [widgetLoader], [appTitle]
class DynamicRouterConfig {
  /// The ID of the main menu configuration (e.g., 'ADMIN_DEFAULT')
  /// If null, uses the first configuration from the list
  final String? mainConfigId;

  /// Builder for the main dashboard widget
  /// If null, uses widgetLoader with the first menu option's widgetName
  final Widget Function()? dashboardBuilder;

  /// Function to load widgets by name (typically from WidgetRegistry)
  /// Required parameter
  final Widget Function(String widgetName, [Map<String, dynamic>? args])
  widgetLoader;

  /// The app title shown in login screen
  /// Required parameter
  final String appTitle;

  /// Initial route location (default: '/')
  final String initialLocation;

  /// Optional splash screen widget to show during loading
  final Widget? splashScreen;

  /// Optional FAB builder for dashboard (receives MenuConfiguration)
  /// Used to add additional FABs that appear above the AI FAB
  final Widget Function(MenuConfiguration)? dashboardFabBuilder;

  const DynamicRouterConfig({
    this.mainConfigId,
    this.dashboardBuilder,
    required this.widgetLoader,
    required this.appTitle,
    this.initialLocation = '/',
    this.splashScreen,
    this.dashboardFabBuilder,
  });
}

/// Creates a dynamic GoRouter based on menu configurations.
///
/// This function handles:
/// - Main app shell with menu
/// - Authentication redirects
/// - Route generation from menu options
GoRouter createDynamicAppRouter(
  List<MenuConfiguration> configurations, {
  required DynamicRouterConfig config,
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  final navKey = rootNavigatorKey ?? GlobalKey<NavigatorState>();

  // Find main config - use provided ID or first available
  final mainConfig = config.mainConfigId != null
      ? configurations.firstWhere(
          (c) => c.menuConfigurationId == config.mainConfigId,
          orElse: () => configurations.isNotEmpty
              ? configurations.first
              : MenuConfiguration(
                  menuOptions: [],
                  appId: 'DEFAULT',
                  name: config.appTitle,
                ),
        )
      : (configurations.isNotEmpty
            ? configurations.first
            : MenuConfiguration(
                menuOptions: [],
                appId: 'DEFAULT',
                name: config.appTitle,
              ));

  // Get dashboard widget - use provided builder or load from first menu option
  Widget getDashboard() {
    if (config.dashboardBuilder != null) {
      return config.dashboardBuilder!();
    }
    // Find the main/dashboard widget from menu options
    final mainOption = mainConfig.menuOptions.firstWhere(
      (o) => o.route == '/' || o.sequenceNum == 0,
      orElse: () => mainConfig.menuOptions.isNotEmpty
          ? mainConfig.menuOptions.first
          : const MenuOption(title: 'Main', widgetName: 'Unknown'),
    );
    return config.widgetLoader(mainOption.widgetName ?? 'Unknown', {});
  }

  return GoRouter(
    navigatorKey: navKey,
    initialLocation: config.initialLocation,
    onException: (context, state, router) {
      // Handle invalid routes gracefully - redirect to home
      router.go('/');
    },
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
              menuConfiguration: mainConfig,
              menuIndex: 0,
              actions: [
                IconButton(
                  key: const Key('logoutButton'),
                  icon: const Icon(
                    Icons.do_not_disturb,
                    key: Key('HomeFormAuth'),
                  ),
                  tooltip: 'Logout',
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              suppressBlocMenuConfig: true,
              tabWidgetLoader: config.widgetLoader,
              floatingActionButton: config.dashboardFabBuilder != null
                  ? config.dashboardFabBuilder!(mainConfig)
                  : null,
              child: getDashboard(),
            );
          } else {
            return HomeForm(
              menuConfiguration: mainConfig,
              title: config.appTitle,
            );
          }
        },
      ),

      // Main Shell - only add if there are routes
      if (_generateRoutes(mainConfig, config.widgetLoader).isNotEmpty)
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
              tabWidgetLoader: config.widgetLoader,
              suppressBlocMenuConfig:
                  false, // Allow BLoC updates for dynamic menus
              child: child,
            );
          },
          routes: _generateRoutes(mainConfig, config.widgetLoader),
        ),

      // Dynamic fallback route - catches routes for dynamically created menu options
      // This allows new menu options added after app startup to work
      ShellRoute(
        builder: (context, state, child) {
          final path = state.uri.path;
          // Get current menu configuration from BLoC
          final menuConfigBloc = context.read<MenuConfigBloc?>();
          final currentConfig =
              menuConfigBloc?.state.menuConfiguration ?? mainConfig;

          // Find the menu option for this path
          int menuIndex = 0;
          for (int i = 0; i < currentConfig.menuOptions.length; i++) {
            if (currentConfig.menuOptions[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: currentConfig,
            menuIndex: menuIndex,
            tabWidgetLoader: config.widgetLoader,
            suppressBlocMenuConfig: false,
            child: child,
          );
        },
        routes: [
          // Wildcard route to catch all dynamic paths
          GoRoute(
            path: '/:path',
            builder: (context, state) {
              final path = '/${state.pathParameters['path']}';
              // Look up the menu option from current BLoC state
              final menuConfigBloc = context.read<MenuConfigBloc?>();
              final currentConfig =
                  menuConfigBloc?.state.menuConfiguration ?? mainConfig;

              // Find the option with this route
              final option = currentConfig.menuOptions.firstWhere(
                (o) => o.route == path,
                orElse: () =>
                    const MenuOption(title: 'Not Found', widgetName: 'Unknown'),
              );

              if (option.widgetName == 'Unknown') {
                return Center(child: Text('Route not found: $path'));
              }

              Map<String, dynamic> args = {};
              if (option.itemKey != null) args['key'] = option.itemKey;
              return config.widgetLoader(option.widgetName!, args);
            },
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _generateRoutes(
  MenuConfiguration config,
  Widget Function(String, [Map<String, dynamic>?]) widgetLoader,
) {
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
          return widgetLoader(option.widgetName ?? 'Unknown', args);
        },
      ),
    );
  }
  return routes;
}
