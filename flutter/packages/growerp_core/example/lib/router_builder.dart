import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'widget_registry.dart';
import 'views/core_dashboard.dart';

/// Builds a GoRouter dynamically from a list of MenuConfigurations
GoRouter createDynamicCoreRouter(
  List<MenuConfiguration> configurations, {
  String initialLocation = '/',
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  final coreConfig = configurations.firstWhere(
    (c) => c.menuConfigurationId == 'CORE_EXAMPLE_DEFAULT',
    orElse: () => configurations.isNotEmpty
        ? configurations.first
        : const MenuConfiguration(
            menuOptions: [],
            appId: 'DEFAULT',
            name: 'Core Example',
          ),
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
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return AuthenticatedDisplayMenuOption(
              menuConfiguration: coreConfig,
              menuIndex: 0,
              child: const CoreDashboard(),
            );
          } else {
            return HomeForm(
              menuConfiguration: coreConfig,
              title: 'GrowERP Core Example',
            );
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (int i = 0; i < coreConfig.menuOptions.length; i++) {
            if (coreConfig.menuOptions[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return AuthenticatedDisplayMenuOption(
            menuConfiguration: coreConfig,
            menuIndex: menuIndex,
            child: child,
          );
        },
        routes: _generateRoutes(coreConfig),
      ),
    ],
  );
}

List<RouteBase> _generateRoutes(MenuConfiguration config) {
  List<RouteBase> routes = [];
  Set<String> processedPaths = {};

  for (var option in config.menuOptions) {
    if (option.route == null || option.route == '/' || option.route!.isEmpty) {
      continue;
    }

    if (processedPaths.contains(option.route)) continue;
    processedPaths.add(option.route!);

    routes.add(
      GoRoute(
        path: option.route!,
        builder: (context, state) {
          return WidgetRegistry.getWidget(option.widgetName ?? 'Unknown');
        },
      ),
    );
  }
  return routes;
}
