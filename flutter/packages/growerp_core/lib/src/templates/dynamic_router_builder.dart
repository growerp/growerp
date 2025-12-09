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

  /// The ID prefix for accounting menu options (e.g., 'ADMIN_ACCOUNTING')
  /// Only needed if [hasAccountingSubmenu] is true
  final String? accountingRootOptionId;

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

  /// Whether this app has an accounting submenu that needs its own shell
  /// Default: false
  final bool hasAccountingSubmenu;

  /// Optional splash screen widget to show during loading
  final Widget? splashScreen;

  /// Optional FAB builder for dashboard (receives MenuConfiguration)
  /// Used to add additional FABs that appear above the AI FAB
  final Widget Function(MenuConfiguration)? dashboardFabBuilder;

  /// Optional FAB builder for accounting menu (receives MenuConfiguration)
  /// Used to add additional FABs that appear above the AI FAB
  final Widget Function(MenuConfiguration)? accountingFabBuilder;

  const DynamicRouterConfig({
    this.mainConfigId,
    this.accountingRootOptionId,
    this.dashboardBuilder,
    required this.widgetLoader,
    required this.appTitle,
    this.initialLocation = '/',
    this.hasAccountingSubmenu = false,
    this.splashScreen,
    this.dashboardFabBuilder,
    this.accountingFabBuilder,
  });
}

/// Creates a dynamic GoRouter based on menu configurations.
///
/// This function handles:
/// - Main app shell with filtered menu (excluding accounting sub-items if applicable)
/// - Accounting sub-app shell with its own menu (if hasAccountingSubmenu is true)
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

  // Create accounting sub-configuration only if needed
  MenuConfiguration? accountingConfig;
  if (config.hasAccountingSubmenu && config.accountingRootOptionId != null) {
    accountingConfig = _createSubConfiguration(
      mainConfig,
      config.accountingRootOptionId!,
      'ACCOUNTING_SYNTHESISED',
      'Accounting Menu',
    );
  }

  // Filter mainConfig to exclude accounting sub-menu items for the main display
  final mainDisplayConfig = config.hasAccountingSubmenu
      ? mainConfig.copyWith(
          menuOptions: mainConfig.menuOptions
              .where(
                (option) =>
                    option.route == null ||
                    !option.route!.startsWith('/accounting/'),
              )
              .toList(),
        )
      : mainConfig;

  // Get dashboard widget - use provided builder or load from first menu option
  Widget getDashboard() {
    if (config.dashboardBuilder != null) {
      return config.dashboardBuilder!();
    }
    // Find the main/dashboard widget from menu options
    final mainOption = mainDisplayConfig.menuOptions.firstWhere(
      (o) => o.route == '/' || o.sequenceNum == 0,
      orElse: () => mainDisplayConfig.menuOptions.isNotEmpty
          ? mainDisplayConfig.menuOptions.first
          : const MenuOption(title: 'Main', widgetName: 'Unknown'),
    );
    return config.widgetLoader(mainOption.widgetName ?? 'Unknown', {});
  }

  return GoRouter(
    navigatorKey: navKey,
    initialLocation: config.initialLocation,
    onException: (context, state, router) {
      // Handle invalid routes gracefully - just log and redirect to home
      // Note: Cannot show snackbar here as there's no Scaffold in navigator context
      debugPrint(
        'GoRouter: No route found for ${state.uri.path}, redirecting to home',
      );
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
              menuConfiguration: mainDisplayConfig,
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
                  ? config.dashboardFabBuilder!(mainDisplayConfig)
                  : null,
              child: getDashboard(),
            );
          } else {
            return HomeForm(
              menuConfiguration: mainDisplayConfig,
              title: config.appTitle,
            );
          }
        },
      ),

      // Main Shell - only add if there are routes
      if (_generateRoutes(
        mainDisplayConfig,
        config.widgetLoader,
        excludePrefix: config.hasAccountingSubmenu ? '/accounting' : null,
      ).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
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
                  icon: const Icon(
                    Icons.do_not_disturb,
                    key: Key('HomeFormAuth'),
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              tabWidgetLoader: config.widgetLoader,
              suppressBlocMenuConfig: true,
              child: child,
            );
          },
          routes: _generateRoutes(
            mainDisplayConfig,
            config.widgetLoader,
            excludePrefix: config.hasAccountingSubmenu ? '/accounting' : null,
          ),
        ),

      // Accounting Shell - only add if hasAccountingSubmenu and there are routes
      if (config.hasAccountingSubmenu &&
          accountingConfig != null &&
          _generateRoutes(accountingConfig, config.widgetLoader).isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            int menuIndex = 0;
            final path = state.uri.path;
            for (int i = 0; i < accountingConfig!.menuOptions.length; i++) {
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
                  icon: const Icon(
                    Icons.do_not_disturb,
                    key: Key('HomeFormAuth'),
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
              tabWidgetLoader: config.widgetLoader,
              suppressBlocMenuConfig: true,
              floatingActionButton: config.accountingFabBuilder != null
                  ? config.accountingFabBuilder!(accountingConfig)
                  : null,
              child: child,
            );
          },
          routes: _generateRoutes(accountingConfig, config.widgetLoader),
        ),
    ],
  );
}

List<RouteBase> _generateRoutes(
  MenuConfiguration config,
  Widget Function(String, [Map<String, dynamic>?]) widgetLoader, {
  String? excludePrefix,
}) {
  List<RouteBase> routes = [];
  Set<String> processedPaths = {};

  for (var option in config.menuOptions) {
    if (!option.isActive) continue;
    if (option.route == null || option.route == '/' || option.route!.isEmpty) {
      continue;
    }
    if (excludePrefix != null && option.route!.startsWith(excludePrefix)) {
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

/// Creates a virtual MenuConfiguration for a submenu (e.g. Accounting)
MenuConfiguration _createSubConfiguration(
  MenuConfiguration fullConfig,
  String rootOptionId,
  String newConfigId,
  String newName,
) {
  MenuOption? rootOption;
  try {
    rootOption = fullConfig.menuOptions.firstWhere(
      (o) => o.menuOptionId == rootOptionId,
    );
  } catch (_) {}

  String prefix = rootOptionId.replaceAll('_ACCOUNTING', '_ACC_');

  List<MenuOption> subOptions = fullConfig.menuOptions
      .where((o) => o.menuOptionId?.startsWith(prefix) ?? false)
      .toList();

  if (rootOption != null) {
    subOptions.insert(
      0,
      rootOption.copyWith(title: 'Dashboard', sequenceNum: 0, children: []),
    );
  }

  subOptions.sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

  return MenuConfiguration(
    menuConfigurationId: newConfigId,
    appId: fullConfig.appId,
    name: newName,
    menuOptions: subOptions,
  );
}
