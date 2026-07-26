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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/growerp_sales.dart';

/// Canonical menu configuration for Sales example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const salesMenuConfig = MenuConfiguration(
  menuConfigurationId: 'SALES_EXAMPLE',
  appId: 'sales_example',
  name: 'Sales Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'SALES_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'SalesDashboard',
    ),
    MenuItem(
      menuItemId: 'SALES_CRM',
      title: 'Opportunities',
      route: '/crm',
      iconName: 'campaign',
      sequenceNum: 20,
      widgetName: 'OpportunityList',
    ),
    MenuItem(
      menuItemId: 'SALES_PIPELINE',
      title: 'Pipeline',
      route: '/pipeline',
      iconName: 'view_kanban',
      sequenceNum: 30,
      widgetName: 'OpportunityPipeline',
    ),
  ],
);

/// Creates a static go_router for the sales example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createSalesExampleRouter() {
  return createStaticAppRouter(
    menuConfig: salesMenuConfig,
    appTitle: 'GrowERP Sales Example',
    dashboard: const SalesDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/crm' => const OpportunityList(),
      '/pipeline' => const OpportunityPipeline(),
      _ => const SalesDashboard(),
    },
  );
}

/// Simple dashboard for sales example
class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final dashboardItems = salesMenuConfig.menuItems
            .where((item) => item.route != '/' && item.route != null)
            .toList();

        return DashboardGrid(
          items: dashboardItems,
          stats: state.authenticate?.stats,
        );
      },
    );
  }
}
