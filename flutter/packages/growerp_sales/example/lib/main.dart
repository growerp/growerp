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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/growerp_sales.dart';

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
      title: 'GrowERP Sales Example',
      router: createSalesExampleRouter(),
      extraDelegates: const [SalesLocalizations.delegate],
      extraBlocProviders: getSalesBlocProviders(restClient),
    ),
  );
}

/// Static menu configuration
const salesMenuConfig = MenuConfiguration(
  menuConfigurationId: 'SALES_EXAMPLE',
  appId: 'sales_example',
  name: 'Sales Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'SALES_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'SalesDashboard',
    ),
    MenuItem(
      itemKey: 'SALES_CRM',
      title: 'Opportunities',
      route: '/crm',
      iconName: 'campaign',
      sequenceNum: 20,
      widgetName: 'OpportunityList',
    ),
  ],
);

/// Creates a static go_router for the sales example app using shared helper
GoRouter createSalesExampleRouter() {
  return createStaticAppRouter(
    menuConfig: salesMenuConfig,
    appTitle: 'GrowERP Sales Example',
    dashboard: const SalesDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/crm' => const OpportunityList(),
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

        final authenticate = state.authenticate!;
        return DashboardGrid(
          itemCount: 1,
          itemBuilder: (context, index) {
            return DashboardCard(
              title: 'Opportunities',
              iconName: 'campaign',
              route: '/crm',
              stats: 'Opportunities: ${authenticate.stats?.opportunities ?? 0}',
            );
          },
        );
      },
    );
  }
}
