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
class DynamicRouterConfig {
  /// The ID of the main menu configuration (e.g., 'ADMIN_DEFAULT', 'HOTEL_DEFAULT')
  final String mainConfigId;

  /// The ID prefix for accounting menu options (e.g., 'ADMIN_ACCOUNTING', 'HOTEL_ACCOUNTING')
  final String accountingRootOptionId;

  /// Builder for the main dashboard widget
  final Widget Function() dashboardBuilder;

  /// Function to load widgets by name (typically from WidgetRegistry)
  final Widget Function(String widgetName, Map<String, dynamic> args)
  widgetLoader;

  /// The app title shown in login screen
  final String appTitle;

  /// Initial route location
  final String initialLocation;

  const DynamicRouterConfig({
    required this.mainConfigId,
    required this.accountingRootOptionId,
    required this.dashboardBuilder,
    required this.widgetLoader,
    required this.appTitle,
    this.initialLocation = '/',
  });
}

/// Creates a dynamic GoRouter based on menu configurations.
///
/// This function handles:
/// - Main app shell with filtered menu (excluding accounting sub-items)
/// - Accounting sub-app shell with its own menu
/// - Authentication redirects
/// - Route generation from menu options
GoRouter createDynamicAppRouter(
  List<MenuConfiguration> configurations, {
  required DynamicRouterConfig config,
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  // Find main config
  final mainConfig = configurations.firstWhere(
    (c) => c.menuConfigurationId == config.mainConfigId,
    orElse: () => configurations.isNotEmpty
        ? configurations.first
        : MenuConfiguration(
            menuOptions: [],
            appId: 'DEFAULT',
            name: config.appTitle,
          ),
  );

  // Create accounting sub-configuration
  final accountingConfig = _createSubConfiguration(
    mainConfig,
    config.accountingRootOptionId,
    'ACCOUNTING_SYNTHESISED',
    'Accounting Menu',
  );

  // Filter mainConfig to exclude accounting sub-menu items for the main display
  // Keep items where route is null OR route does not start with /accounting/
  final mainDisplayConfig = mainConfig.copyWith(
    menuOptions: mainConfig.menuOptions
        .where(
          (option) =>
              option.route == null || !option.route!.startsWith('/accounting/'),
        )
        .toList(),
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: config.initialLocation,
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
              menuConfiguration: mainDisplayConfig,
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
              child: config.dashboardBuilder(),
              suppressBlocMenuConfig: true,
            );
          } else {
            return HomeForm(
              menuConfiguration: mainDisplayConfig,
              title: config.appTitle,
            );
          }
        },
      ),

      // Main Shell - only add if there are routes (excluding /accounting routes)
      if (_generateRoutes(
        mainDisplayConfig,
        config.widgetLoader,
        excludePrefix: '/accounting',
      ).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            // Calculate menu index
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < mainDisplayConfig.menuOptions.length; i++) {
              if (mainDisplayConfig.menuOptions[i].route == path) {
                menuIndex = i;
                break;
              }
            }
            return DisplayMenuOption(
              menuConfiguration: mainDisplayConfig,
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
              tabWidgetLoader: config.widgetLoader,
              suppressBlocMenuConfig: true,
            );
          },
          routes: _generateRoutes(
            mainDisplayConfig,
            config.widgetLoader,
            excludePrefix: '/accounting',
          ),
        ),

      // Accounting Shell - only add if there are routes
      if (_generateRoutes(accountingConfig, config.widgetLoader).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < accountingConfig.menuOptions.length; i++) {
              if (accountingConfig.menuOptions[i].route == path) {
                menuIndex = i;
                break;
              }
            }
            return DisplayMenuOption(
              menuConfiguration: accountingConfig,
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
              tabWidgetLoader: config.widgetLoader,
              suppressBlocMenuConfig: true,
            );
          },
          routes: _generateRoutes(accountingConfig, config.widgetLoader),
        ),
    ],
  );
}

List<RouteBase> _generateRoutes(
  MenuConfiguration config,
  Widget Function(String, Map<String, dynamic>) widgetLoader, {
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

          return widgetLoader(option.widgetName ?? 'Unknown', args);
        },
      ),
    );
  }
  return routes;
}

/// Creates a virtual MenuConfiguration for a submenu (e.g. Accounting)
/// by extracting specific accounting menu options.
MenuConfiguration _createSubConfiguration(
  MenuConfiguration fullConfig,
  String rootOptionId,
  String newConfigId,
  String newName,
) {
  // Find the root option (e.g. "Accounting" main item)
  MenuOption? rootOption;
  try {
    rootOption = fullConfig.menuOptions.firstWhere(
      (o) => o.menuOptionId == rootOptionId,
    );
  } catch (_) {
    // Root option not found
  }

  // For accounting submenu, we get options that start with the accounting prefix
  // e.g., ADMIN_ACC_SALES, ADMIN_ACC_PURCHASE, etc.
  String prefix = rootOptionId.replaceAll('_ACCOUNTING', '_ACC_');

  List<MenuOption> subOptions = fullConfig.menuOptions
      .where((o) => o.menuOptionId?.startsWith(prefix) ?? false)
      .toList();

  // Add the root accounting option as dashboard
  if (rootOption != null) {
    subOptions.insert(
      0,
      rootOption.copyWith(title: 'Dashboard', sequenceNum: 0, children: []),
    );
  }

  // Sort by sequence number
  subOptions.sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

  return MenuConfiguration(
    menuConfigurationId: newConfigId,
    appId: fullConfig.appId,
    name: newName,
    menuOptions: subOptions,
  );
}
