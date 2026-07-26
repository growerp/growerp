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
      applicationId: 'AppAdmin',
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
    MenuItem(
      itemKey: 'MFG_ROUTING',
      title: 'Routings',
      route: '/manufacturing/routing',
      iconName: 'route',
      sequenceNum: 50,
      widgetName: 'RoutingList',
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
      '/manufacturing/routing' => const RoutingList(),
      _ => const ManufacturingDashboard(),
    },
  );
}

/// Dashboard for manufacturing example — styled to match AdminDashboardContent.
class ManufacturingDashboard extends StatelessWidget {
  const ManufacturingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = manufacturingMenuConfig.menuItems
            .where((item) =>
                item.isActive && item.route != null && item.route != '/')
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardItems,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
          ),
        );
      },
    );
  }
}
