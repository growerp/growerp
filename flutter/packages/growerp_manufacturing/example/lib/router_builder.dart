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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';

/// Canonical menu configuration for the Manufacturing example app.
///
/// Used by both the production app (main.dart) and all integration tests.
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

/// Creates a static go_router for the manufacturing example app.
///
/// Used by both the production app (main.dart) and all integration tests.
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

/// Dashboard for the manufacturing example app.
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
