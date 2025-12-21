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
  menuItems: [
    MenuItem(
      menuItemId: 'CATALOG_MAIN',
      title: 'Catalog',
      route: '/',
      iconName: 'category',
      sequenceNum: 10,
      widgetName: 'CatalogDashboard',
    ),
    MenuItem(
      menuItemId: 'CATALOG_PRODUCTS',
      title: 'Products',
      route: '/products',
      iconName: 'products',
      sequenceNum: 20,
      widgetName: 'ProductList',
    ),
    MenuItem(
      menuItemId: 'CATALOG_CATEGORIES',
      title: 'Categories',
      route: '/categories',
      iconName: 'folder',
      widgetName: 'CategoryList',
    ),
    MenuItem(
      menuItemId: 'CATALOG_SUBSCRIPTIONS',
      title: 'Subscriptions',
      route: '/subscriptions',
      iconName: 'subscriptions',
      sequenceNum: 40,
      widgetName: 'SubscriptionList',
    ),
  ],
);

/// Creates a static go_router for the catalog example app using shared helper
GoRouter createCatalogExampleRouter() {
  return createStaticAppRouter(
    menuConfig: catalogMenuConfig,
    appTitle: 'GrowERP Catalog Example',
    dashboard: const CatalogDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/products' => const ProductList(),
      '/categories' => const CategoryList(),
      '/subscriptions' => const SubscriptionList(),
      _ => const CatalogDashboard(),
    },
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
        final dashboardItems = catalogMenuConfig.menuItems
            .where((item) => item.route != '/' && item.route != null)
            .toList();

        return DashboardGrid(
          itemCount: dashboardItems.length,
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return DashboardCard(
              title: item.title,
              iconName: item.iconName ?? 'dashboard',
              route: item.route!,
              stats: _getStatsForItem(item, authenticate),
            );
          },
        );
      },
    );
  }

  String _getStatsForItem(MenuItem item, Authenticate auth) {
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
