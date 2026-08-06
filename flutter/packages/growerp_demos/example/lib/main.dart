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
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_demos/growerp_demos.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

// ── Menu config (exported for integration tests) ──────────────────────────────

const demosMenuConfig = MenuConfiguration(
  menuConfigurationId: 'DEMOS_EXAMPLE',
  appId: 'demos_example',
  name: 'GrowERP Demos',
  menuItems: [
    MenuItem(
      itemKey: 'DEMOS_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'DemosDashboard',
    ),
    MenuItem(
      itemKey: 'DEMOS_LIST',
      title: 'Demos',
      route: '/demos',
      iconName: 'play_circle',
      sequenceNum: 20,
      widgetName: 'DemoList',
    ),
  ],
);

// ── Localization delegates (exported for integration tests) ───────────────────

final List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  ManufacturingLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  DemosLocalizations.delegate,
  ManufLinerLocalizations.delegate,
];

// ── BLoC providers (exported for integration tests) ───────────────────────────

List<BlocProvider> getDemosBlocProviders(RestClient restClient) => [
  ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
  ...getCatalogBlocProviders(restClient, 'AppAdmin'),
  ...getInventoryBlocProviders(restClient, 'AppAdmin'),
  ...getManufacturingBlocProviders(restClient),
  ...getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
  ...getLinerBlocProviders(restClient),
];

// ── Router (exported for integration tests) ───────────────────────────────────

GoRouter createDemosExampleRouter() {
  return createStaticAppRouter(
    menuConfig: demosMenuConfig,
    appTitle: 'GrowERP Demos',
    dashboard: const _DemosDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/demos' => const DemoListScreen(),
      _ => const _DemosDashboard(),
    },
  );
}

// ── Widget registrations ──────────────────────────────────────────────────────

List<Map<String, GrowerpWidgetBuilder>> demosWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getManufacturingWidgets(),
  getOrderAccountingWidgets(),
  {'DemoList': (args) => const DemoListScreen()},
];

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  final RestClient restClient = RestClient(await buildDioClient());
  final WsClient chatClient = WsClient('chat');
  final WsClient notificationClient = WsClient('notws');

  runApp(
    TopApp(
      restClient: restClient,
      applicationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Demos',
      router: createDemosExampleRouter(),
      extraDelegates: delegates,
      extraBlocProviders: getDemosBlocProviders(restClient),
      widgetRegistrations: demosWidgetRegistrations,
    ),
  );
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class _DemosDashboard extends StatelessWidget {
  const _DemosDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('DemosDashboard'),
      backgroundColor: Colors.transparent,
      body: DashboardGrid(
        items: demosMenuConfig.menuItems
            .where(
              (item) =>
                  item.isActive && item.route != null && item.route != '/',
            )
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum)),
        stats: context.read<AuthBloc>().state.authenticate?.stats,
        onRefresh: () async => context.read<AuthBloc>().add(AuthLoad()),
      ),
    );
  }
}
