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
import 'package:adk_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_adk/src/integration_test/adk_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP ADK governance integration test', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());

    final router = createDynamicAdkRouter([
      adkMenuConfig,
    ], rootNavigatorKey: GlobalKey<NavigatorState>());

    final menuConfigBloc = MenuConfigBloc(restClient, 'adk_example')
      ..add(MenuConfigUpdateLocal(adkMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      adkMenuConfig,
      [
        ...CoreLocalizations.localizationsDelegates,
        UserCompanyLocalizations.delegate,
      ],
      restClient: restClient,
      clear: true,
      title: "ADK Test",
      widgetRegistrations: adkWidgetRegistrations,
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Re-seed the local menu so the ADK routes are present after login
    // (TopApp loads the backend seed menu on authentication).
    menuConfigBloc.add(MenuConfigUpdateLocal(adkMenuConfig));
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byKey(const Key('tap/adk-agents')))) break;
    }

    // Agents: create a safe-by-default (read-only) agent via the dialog,
    // asserting the governance controls exist, then confirm it is listed.
    await AdkTest.selectAgents(tester);
    await AdkTest.addReadOnlyAgent(tester, 'TestReadOnlyAgent');
    await AdkTest.checkAgent(tester, 'TestReadOnlyAgent');

    // Governance surfaces render for the logged-in company.
    await AdkTest.selectApprovals(tester);
    await AdkTest.selectActions(tester);

    await CommonTest.logout(tester);
  });
}
