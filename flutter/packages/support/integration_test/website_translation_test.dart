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

// Website Translation screen of the support app.
//
// The test drives the list and the new-translation dialog, but never starts a
// translation: that would spend LLM credits and take minutes, neither of which
// belongs in CI. What is covered is everything around it — the list loads from
// the backend, the dialog offers the six languages the apps support minus the
// one the site is written in, and the two validations refuse an incomplete
// request before it can reach the server.
//
// The menu configuration is built here instead of being fetched: the real
// SUPPORT_WEBSITE_TRANS item is restricted with userGroupsJson, and the
// authenticate response for SystemSupport carries no userGroup, so
// display_menu_option._hasAccess hides it (see the note in screenshot_test.dart).
// A local config also gives the router the route, which it generates from the
// menu items it is handed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:support/main.dart';
import 'package:support/views/support_dashboard_content.dart';

const _menuConfig = MenuConfiguration(
  menuConfigurationId: 'SUPPORT_DEFAULT',
  appId: 'support',
  name: 'Support',
  menuItems: [
    // no userGroups: the gating is not what this test is about
    MenuItem(
      menuItemId: 'SUPPORT_WEBSITE_TRANS',
      title: 'Website Translation',
      route: '/websiteTranslation',
      iconName: 'translate',
      widgetName: 'WebsiteTranslationList',
      sequenceNum: 10,
    ),
  ],
);

GoRouter createTranslationTestRouter() {
  WidgetRegistry.clear();
  for (final reg in supportWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_menuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'SUPPORT_DEFAULT',
      dashboardBuilder: () => const SupportDashboardContent(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Support',
    ),
  );
}

/// The list fetches on init, so give the backend call time to land.
Future<void> _waitForKey(WidgetTester tester, String key) async {
  for (int i = 0; i < 20; i++) {
    if (tester.any(find.byKey(Key(key)))) return;
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(
    find.byKey(Key(key)),
    findsOneWidget,
    reason: 'Timed out waiting for key "$key"',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const applicationId = 'AppSupport';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('website translation list and dialog', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    final router = createTranslationTestRouter();

    await CommonTest.startTestApp(
      tester,
      router,
      _menuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getSupportBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Website Translation',
    );

    // the support app has no self-registration, log in as the seeded account
    await CommonTest.login(
      tester,
      username: 'SystemSupport',
      password: 'moqui',
    );

    // ---- the list ----------------------------------------------------------
    router.go('/websiteTranslation');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _waitForKey(tester, '/websiteTranslation');
    expect(find.byKey(const Key('websiteTranslationSearch')), findsOneWidget);
    expect(find.byKey(const Key('addNewWebsiteTranslation')), findsOneWidget);

    // ---- the dialog --------------------------------------------------------
    await tester.tap(find.byKey(const Key('addNewWebsiteTranslation')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('WebsiteTranslationDialog')), findsOneWidget);
    expect(find.byKey(const Key('ownerPartyId')), findsOneWidget);
    expect(find.byKey(const Key('sourceLocale')), findsOneWidget);

    // every language the apps support except the one the site is written in,
    // which defaults to english; see WebsiteTranslation.supportedLocales
    for (final locale in WebsiteTranslation.supportedLocales) {
      expect(
        find.byKey(Key('locale_$locale')),
        findsOneWidget,
        reason: '$locale should be offered as a target language',
      );
    }
    expect(
      find.byKey(const Key('locale_en')),
      findsNothing,
      reason: 'the source language must not be offered as a target',
    );

    // ---- validation: no owner ----------------------------------------------
    // starting without an owner must not reach the backend
    await tester.ensureVisible(find.byKey(const Key('startTranslation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('startTranslation')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('WebsiteTranslationDialog')),
      findsOneWidget,
      reason: 'the dialog stays open until the request is valid',
    );
    expect(find.text('Select the owner'), findsOneWidget);

    // ---- validation: no language -------------------------------------------
    // pick the first owner the backend offers, leave every language unticked
    await tester.enterText(find.byKey(const Key('ownerPartyId')), 'a');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final firstOption = find.byKey(const Key('autocompleteOption0'));
    if (firstOption.evaluate().isNotEmpty) {
      await tester.tap(firstOption);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('startTranslation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('startTranslation')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('WebsiteTranslationDialog')),
        findsOneWidget,
        reason: 'a translation without a target language must be refused',
      );
    }

    // ---- close -------------------------------------------------------------
    // the dialog is dismissible, nothing was created
    Navigator.of(tester.element(find.byKey(const Key('startTranslation')))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('WebsiteTranslationDialog')), findsNothing);
    await _waitForKey(tester, '/websiteTranslation');
  });
}
