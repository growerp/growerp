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
      menuOptionItemId: 'INV_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      menuOptionItemId: 'INV_ASSETS',
      title: 'Assets',
      route: '/assets',
      iconName: 'money',
      sequenceNum: 20,
    ),
    MenuItem(
      menuOptionItemId: 'INV_LOCATIONS',
      title: 'WH Locations',
      route: '/locations',
      iconName: 'location_on',
      sequenceNum: 30,
    ),
  ],
);

/// Creates a static go_router for the inventory example app
GoRouter createInventoryExampleRouter() {
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
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return const DisplayMenuOption(
              menuConfiguration: inventoryMenuConfig,
              menuIndex: 0,
              child: InventoryDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: inventoryMenuConfig,
              title: 'GrowERP Inventory Example',
            );
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (int i = 0; i < inventoryMenuConfig.menuItems.length; i++) {
            if (inventoryMenuConfig.menuItems[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: inventoryMenuConfig,
            menuIndex: menuIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetList(),
          ),
          GoRoute(
            path: '/locations',
            builder: (context, state) =>
                const LocationList(key: Key('Locations')),
          ),
        ],
      ),
    ],
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
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _DashboardCard(
                  title: 'Assets',
                  iconName: 'money',
                  route: '/assets',
                  stats: 'Assets: ${authenticate.stats?.assets ?? 0}',
                );
              } else {
                return _DashboardCard(
                  title: 'WH Locations',
                  iconName: 'location_on',
                  route: '/locations',
                  stats: 'Locations: ${authenticate.stats?.whLocations ?? 0}',
                );
              }
            },
          ),
        );
      },
    );
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
              const SizedBox(height: 8),
              Text(stats, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
