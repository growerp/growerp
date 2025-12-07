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
import 'package:core_example/main.dart';
import 'package:core_example/router_builder.dart'; // For createDynamicCoreRouter
import 'package:flutter/material.dart'; // For GlobalKey, NavigatorState
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
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
      menuOptions: [
        MenuOption(
          menuOptionId: 'CORE_MAIN',
          title: 'Main',
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 10,
          widgetName: 'CoreDashboard',
          isActive: true,
        ),
        MenuOption(
          menuOptionId: 'CORE_COMPANY',
          title: 'Organization',
          route: '/company',
          iconName: 'business',
          sequenceNum: 20,
          widgetName: 'CoreDashboard',
          isActive: true,
        ),
        MenuOption(
          menuOptionId: 'CORE_USER',
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

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      CoreLocalizations.localizationsDelegates,
      restClient: restClient,
      clear: true,
      title: "Core Test",
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Check specific specific widgets as checkCompanyAndAdmin expects AdminDbForm
    SaveTest savedTest = await PersistFunctions.getTest();
    expect(find.text('Organization'), findsOneWidget);
    expect(find.text(savedTest.company!.name!), findsWidgets);
    expect(find.text('User'), findsOneWidget);
    expect(
      find.text('${savedTest.admin!.firstName} ${savedTest.admin!.lastName}'),
      findsWidgets,
    );
    await CommonTest.logout(tester);
  });
}
