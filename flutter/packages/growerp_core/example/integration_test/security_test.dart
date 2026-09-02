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
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Organization -> Security: screen access per user group.
///
/// Unlike core_test.dart this deliberately does NOT re-seed MenuConfigBloc with
/// the local coreMenuConfig: the whole point is the menu the backend returns,
/// filtered by the caller's group and cloned to the organization on first save.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Security grid shows screens and grants access', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());

    final router = createDynamicCoreRouter([
      coreMenuConfig,
    ], rootNavigatorKey: GlobalKey<NavigatorState>());

    final menuConfigBloc = MenuConfigBloc(restClient, 'core_example')
      ..add(MenuConfigUpdateLocal(coreMenuConfig));

    await CommonTest.startTestApp(
      tester,
      router,
      coreMenuConfig,
      // UserCompany delegates too: Organization renders company and user
      // screens from growerp_user_company, whose .of(context)! crashes without
      // its delegate registered here.
      const [
        ...CoreLocalizations.localizationsDelegates,
        UserCompanyLocalizations.delegate,
      ],
      restClient: restClient,
      clear: true,
      title: "Security Test",
      blocProviders: [
        BlocProvider<MenuConfigBloc>.value(value: menuConfigBloc),
        // Organization renders company and user screens, which need the
        // user_company blocs the example app provides via TopApp.
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      ],
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Wait for the backend menu to replace the locally seeded one; the
    // Organization card only exists in the backend configuration.
    for (int i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byKey(const Key('tap/companies')))) break;
    }

    await SecurityTest.selectSecurity(tester);
    await SecurityTest.checkGrid(tester);

    // The organization may not hand out system access.
    await SecurityTest.checkNoSystemColumn(tester);

    // Default policy: a screen with no group list is for the internal groups.
    // Outside users are default deny, so they reach nothing unless named.
    await SecurityTest.checkAccess(tester, 0, 'employee', 'write');
    await SecurityTest.checkAccess(tester, 0, 'other', 'none');

    // Grant, then confirm it survives the reload that follows the save. This
    // is the first write, so it also clones the seed menu for the organization
    // and every menuItemId changes underneath the grid.
    await SecurityTest.setAccess(tester, 0, 'employee', 'view');
    await SecurityTest.checkAccess(tester, 0, 'employee', 'view');

    // Granting the outside group, and leaving the other groups alone.
    await SecurityTest.setAccess(tester, 0, 'other', 'view');
    await SecurityTest.checkAccess(tester, 0, 'other', 'view');
    await SecurityTest.checkAccess(tester, 0, 'employee', 'view');

    // ... and taking it away again.
    await SecurityTest.setAccess(tester, 0, 'other', 'none');
    await SecurityTest.checkAccess(tester, 0, 'other', 'none');

    await CommonTest.logout(tester);
  });
}
