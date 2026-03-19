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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
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
      title: 'GrowERP Manufacturing Example',
      router: createManufacturingExampleRouter(),
      extraDelegates: [
        ManufacturingLocalizations.delegate,
        CatalogLocalizations.delegate,
      ],
      extraBlocProviders: [
        ...getManufacturingBlocProviders(restClient),
        ...getCatalogBlocProviders(restClient, 'AppAdmin'),
      ],
    ),
  );
}

/// Static menu configuration
const manufacturingMenuConfig = MenuConfiguration(
  menuConfigurationId: 'MANUFACTURING_EXAMPLE',
  appId: 'manufacturing_example',
  name: 'Manufacturing Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'MFG_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'ManufacturingDashboard',
    ),
    MenuItem(
      itemKey: 'MFG_PRODUCTS',
      title: 'Products',
      route: '/products',
      iconName: 'category',
      sequenceNum: 20,
      widgetName: 'ProductList',
    ),
    MenuItem(
      itemKey: 'MFG_BOM',
      title: 'Bill of Materials',
      route: '/manufacturing/bom',
      iconName: 'schema',
      sequenceNum: 30,
      widgetName: 'BomList',
    ),
    MenuItem(
      itemKey: 'MFG_WORKORDER',
      title: 'Work Orders',
      route: '/manufacturing/workOrder',
      iconName: 'precision_manufacturing',
      sequenceNum: 40,
      widgetName: 'WorkOrderList',
    ),
  ],
);

/// Creates a static go_router for the manufacturing example app
GoRouter createManufacturingExampleRouter() {
  return createStaticAppRouter(
    menuConfig: manufacturingMenuConfig,
    appTitle: 'GrowERP Manufacturing Example',
    dashboard: const ManufacturingDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/products' => const ProductList(),
      '/manufacturing/bom' => const BomList(),
      '/manufacturing/workOrder' => const WorkOrderList(),
      _ => const ManufacturingDashboard(),
    },
  );
}

/// Simple dashboard for manufacturing example
class ManufacturingDashboard extends StatelessWidget {
  const ManufacturingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final authenticate = state.authenticate!;
        return DashboardGrid(
          itemCount: 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return DashboardCard(
                title: 'Products',
                iconName: 'category',
                route: '/products',
                stats: 'Products: ${authenticate.stats?.products ?? 0}',
              );
            } else if (index == 1) {
              return DashboardCard(
                title: 'Bill of Materials',
                iconName: 'schema',
                route: '/manufacturing/bom',
                stats: 'BOMs defined',
              );
            } else {
              return DashboardCard(
                title: 'Work Orders',
                iconName: 'precision_manufacturing',
                route: '/manufacturing/workOrder',
                stats: 'Production runs',
              );
            }
          },
        );
      },
    );
  }
}
