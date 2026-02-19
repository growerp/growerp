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
import 'package:core_example/router_builder.dart'; // For createDynamicCoreRouter
import 'package:flutter/material.dart'; // For GlobalKey, NavigatorState
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP Core integration test', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    const coreMenuConfig = MenuConfiguration(
      menuConfigurationId: 'CORE_EXAMPLE',
      appId: 'core_example',
      name: 'Core Example Menu',
      menuItems: [
        MenuItem(
          menuItemId: 'CORE_MAIN',
          title: 'Main',
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 10,
          widgetName: 'CoreDashboard',
          isActive: true,
        ),
        MenuItem(
          menuItemId: 'CORE_COMPANY',
          title: 'Organization',
          route: '/company',
          iconName: 'business',
          sequenceNum: 20,
          widgetName: 'CoreDashboard',
          isActive: true,
        ),
        MenuItem(
          menuItemId: 'CORE_USER',
          title: 'Logged in User',
          route: '/user',
          iconName: 'person',
          sequenceNum: 30,
          widgetName: 'CoreDashboard',
          isActive: true,
        ),
      ],
    );

    final router = createDynamicCoreRouter([
      coreMenuConfig,
    ], rootNavigatorKey: GlobalKey<NavigatorState>());

    // Create and seed MenuConfigBloc with the test configuration
    final menuConfigBloc = MenuConfigBloc(restClient, 'core_example')
      ..add(MenuConfigUpdateLocal(coreMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: "Core Test",
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Check that menu option cards are displayed on the dashboard
    // CoreDashboard shows cards for each menu option (excluding '/' and '/about')
    // Use key-based finders since DashboardCard applies text transformations in phone mode
    expect(find.byKey(const Key('tap/company')), findsOneWidget);
    expect(find.byKey(const Key('tap/user')), findsOneWidget);

    // Verify we're authenticated (HomeFormAuth key should be present in logout button icon)
    expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);

    await CommonTest.logout(tester);
  });
}
