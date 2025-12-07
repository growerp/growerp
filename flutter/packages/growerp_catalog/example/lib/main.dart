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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Catalog Example',
      router: createCatalogExampleRouter(),
      extraDelegates: const [CatalogLocalizations.delegate],
      extraBlocProviders: getCatalogBlocProviders(restClient, 'AppAdmin'),
    ),
  );
}

/// Static menu configuration - no backend needed for example apps
const catalogMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CATALOG_EXAMPLE',
  appId: 'catalog_example',
  name: 'Catalog Example Menu',
  menuOptions: [
    MenuOption(
      menuOptionId: 'CATALOG_MAIN',
      title: 'Catalog',
      route: '/',
      iconName: 'category',
      sequenceNum: 10,
      widgetName: 'CatalogDashboard',
    ),
    MenuOption(
      menuOptionId: 'CATALOG_PRODUCTS',
      title: 'Products',
      route: '/products',
      iconName: 'products',
      sequenceNum: 20,
      widgetName: 'ProductList',
    ),
    MenuOption(
      menuOptionId: 'CATALOG_CATEGORIES',
      title: 'Categories',
      route: '/categories',
      iconName: 'folder',
      widgetName: 'CategoryList',
    ),
    MenuOption(
      menuOptionId: 'CATALOG_SUBSCRIPTIONS',
      title: 'Subscriptions',
      route: '/subscriptions',
      iconName: 'subscriptions',
      sequenceNum: 40,
      widgetName: 'SubscriptionList',
    ),
  ],
);

/// Creates a static go_router for the catalog example app
GoRouter createCatalogExampleRouter() {
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
      // Root route - shows home or dashboard
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return DisplayMenuOption(
              menuConfiguration: catalogMenuConfig,
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
              child: const CatalogDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: catalogMenuConfig,
              title: 'GrowERP Catalog Example',
            );
          }
        },
      ),
      // Other routes wrapped in ShellRoute for consistent menu
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (int i = 0; i < catalogMenuConfig.menuOptions.length; i++) {
            if (catalogMenuConfig.menuOptions[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: catalogMenuConfig,
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
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductList(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoryList(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionList(),
          ),
        ],
      ),
    ],
  );
}

/// Simple dashboard for catalog example
class CatalogDashboard extends StatelessWidget {
  const CatalogDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final authenticate = state.authenticate!;
        final dashboardItems = catalogMenuConfig.menuOptions
            .where((item) => item.route != '/' && item.route != null)
            .map(
              (item) => _DashboardCard(
                title: item.title,
                iconName: item.iconName ?? 'dashboard',
                route: item.route!,
                stats: _getStatsForItem(item, authenticate),
              ),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: dashboardItems.length,
            itemBuilder: (context, index) => dashboardItems[index],
          ),
        );
      },
    );
  }

  String _getStatsForItem(MenuOption item, Authenticate auth) {
    switch (item.route) {
      case '/products':
        return 'Products: ${auth.stats?.products ?? 0}';
      case '/categories':
        return 'Categories: ${auth.stats?.categories ?? 0}';
      case '/subscriptions':
        return 'Subscriptions';
      default:
        return '';
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;
  final String stats;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(stats, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
