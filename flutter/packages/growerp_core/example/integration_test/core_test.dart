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

    // After login, TopApp's BlocListener fires MenuConfigLoad which replaces
    // the locally-seeded coreMenuConfig with the backend's seed data (different
    // routes). Re-seed the bloc so CoreDashboard renders the expected keys.
    menuConfigBloc.add(MenuConfigUpdateLocal(coreMenuConfig));

    // Wait for CoreDashboard to rebuild with the re-seeded configuration.
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byKey(const Key('tap/company')))) break;
    }

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
