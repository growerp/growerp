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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';

/// Canonical menu configuration for Inventory example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const inventoryMenuConfig = MenuConfiguration(
  menuConfigurationId: 'INVENTORY_EXAMPLE',
  appId: 'inventory_example',
  name: 'Inventory Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'INV_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'InventoryDashboard',
    ),
    MenuItem(
      itemKey: 'INV_ASSETS',
      title: 'Assets',
      route: '/assets',
      iconName: 'money',
      sequenceNum: 20,
      widgetName: 'AssetList',
    ),
    MenuItem(
      itemKey: 'INV_LOCATIONS',
      title: 'WH Locations',
      route: '/locations',
      iconName: 'location_on',
      sequenceNum: 30,
      widgetName: 'LocationList',
    ),
  ],
);

/// Creates a static go_router for the inventory example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createInventoryExampleRouter() {
  return createStaticAppRouter(
    menuConfig: inventoryMenuConfig,
    appTitle: 'GrowERP Inventory Example',
    dashboard: const InventoryDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/assets' => const AssetList(),
      '/locations' => const LocationList(key: Key('Locations')),
      _ => const InventoryDashboard(),
    },
  );
}

/// Simple dashboard for inventory example
class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        return DashboardGrid(
          items: const [
            MenuItem(
              menuItemId: 'assets',
              title: 'Assets',
              iconName: 'money',
              route: '/assets',
              tileType: 'statistic',
            ),
            MenuItem(
              menuItemId: 'locations',
              title: 'WH Locations',
              iconName: 'location_on',
              route: '/locations',
              tileType: 'statistic',
            ),
          ],
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
