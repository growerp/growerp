/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';

/// Canonical menu configuration for Catalog example app.
///
/// Used by both the production app (main.dart) and all integration tests.
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

/// Creates a static go_router for the catalog example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
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
          items: dashboardItems,
          stats: authenticate.stats,
        );
      },
    );
  }
}
