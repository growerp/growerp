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
import 'package:growerp_inventory/growerp_inventory.dart';
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
      title: 'GrowERP Inventory Example',
      router: createInventoryExampleRouter(),
      extraDelegates: const [InventoryLocalizations.delegate],
      extraBlocProviders: getInventoryBlocProviders(restClient, "AppAdmin"),
    ),
  );
}

/// Static menu configuration
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

/// Creates a static go_router for the inventory example app using shared helper
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

        final authenticate = state.authenticate!;
        return DashboardGrid(
          itemCount: 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return DashboardCard(
                title: 'Assets',
                iconName: 'money',
                route: '/assets',
                stats: 'Assets: ${authenticate.stats?.assets ?? 0}',
              );
            } else {
              return DashboardCard(
                title: 'WH Locations',
                iconName: 'location_on',
                route: '/locations',
                stats: 'Locations: ${authenticate.stats?.whLocations ?? 0}',
              );
            }
          },
        );
      },
    );
  }
}
