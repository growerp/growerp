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

// "Agent Catalog" screen of the support app (AdkAgentCatalogView): the two
// tabs render and their key controls are present. The Suggestion tab's real
// feasibility check needs a live LLM call *and* a real tenant ownerPartyId to
// test cross-tenant with — neither is stable enough to hardcode into a test
// that runs in arbitrary environments, so this stays a structural smoke test.
// The underlying suggest#AgentFunction call itself (including the
// SystemSupport ownerPartyId override) is exercised for the ordinary
// same-tenant case by growerp_adk's adk_function_catalog_test.dart.
//
// Same local-menu approach as website_translation_test.dart: the real
// SUPPORT_CATALOG_PROMOTION item is restricted with userGroupsJson and
// SystemSupport's authenticate response carries no userGroup, so building the
// menu here avoids that unrelated gating.

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
    MenuItem(
      menuItemId: 'SUPPORT_CATALOG_PROMOTION',
      title: 'Agent Catalog',
      route: '/agent-catalog',
      iconName: 'star',
      widgetName: 'AdkAgentCatalogView',
      sequenceNum: 10,
    ),
  ],
);

GoRouter createAgentCatalogTestRouter() {
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const applicationId = 'AppSupport';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('agent catalog: promotion and suggestion tabs render', (
    WidgetTester tester,
  ) async {
    final restClient = RestClient(await buildDioClient());
    final router = createAgentCatalogTestRouter();

    await CommonTest.startTestApp(
      tester,
      router,
      _menuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getSupportBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Agent Catalog',
    );

    await CommonTest.login(
      tester,
      username: 'SystemSupport',
      password: 'moqui',
    );

    router.go('/agent-catalog');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ---- Promotion tab (default) -------------------------------------------
    expect(find.byKey(const Key('agentCatalogPromotionTab')), findsOneWidget);
    expect(find.byKey(const Key('agentCatalogSuggestionTab')), findsOneWidget);
    expect(find.byKey(const Key('refreshCatalogPromotion')), findsOneWidget);

    // ---- Suggestion tab -----------------------------------------------------
    await tester.tap(find.byKey(const Key('agentCatalogSuggestionTab')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(
      find.byKey(const Key('suggestFunctionOwnerPartyId')),
      findsOneWidget,
      reason: 'support needs to name a tenant to test a suggestion for',
    );
    expect(find.byKey(const Key('suggestFunctionDescription')), findsOneWidget);
    expect(find.byKey(const Key('checkSuggestFunction')), findsOneWidget);

    await CommonTest.logout(tester);
  });
}
