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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_marketing_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP marketing setup guide test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createMarketingExampleRouter(),
      marketingMenuConfig,
      marketingExampleDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("applicationId"),
      ),
      widgetRegistrations: [getMarketingWidgets()],
      title: 'GrowERP marketing setup guide test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // The guide is laid out for a wide screen, so its menu entry is left out
    // on a phone: there is nothing to test in the mobile layout.
    if (CommonTest.isPhone()) {
      await CommonTest.logout(tester);
      return;
    }

    await CommonTest.selectOption(tester, '/guide', 'MarketingSetupGuide');

    // The guide opens with a summary of the whole content flow
    expect(find.byKey(const Key('guideIntro')), findsOneWidget,
        reason: 'guide should show its summary description');

    // The first steps are visible without scrolling, each with a status line
    expect(find.byKey(const Key('guideStep0')), findsOneWidget,
        reason: 'AI/voice step should be present');
    expect(find.byKey(const Key('guideStep1')), findsOneWidget,
        reason: 'persona step should be present');
    expect(find.byKey(const Key('guideStatus1')), findsOneWidget,
        reason: 'persona step should show a status line');

    // Tapping the persona step shows the persona list inside the app frame
    await CommonTest.tapByKey(tester, 'guideStep1');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'guideStepPage');
    await CommonTest.checkWidgetKey(tester, 'PersonaList');

    // The back bar returns to the guide, which reloads its state: no persona
    // exists yet, so a step with a live check is not marked done
    await CommonTest.tapByKey(tester, 'backToGuide');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'MarketingSetupGuide');
    expect(
      find.descendant(
        of: find.byKey(const Key('guideStep1')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
      reason: 'persona step should not be marked done without a persona',
    );

    // The engagements step cannot be checked from data: opening it completes
    // it, and it stays completed after returning to the list
    await CommonTest.dragUntil(tester, key: 'guideStep7');
    await CommonTest.tapByKey(tester, 'guideStep7');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'guideStepPage');
    await CommonTest.tapByKey(tester, 'backToGuide');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.dragUntil(tester, key: 'guideStep7');
    expect(
      find.descendant(
        of: find.byKey(const Key('guideStep7')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
      reason: 'opened step should be marked as done',
    );

    await CommonTest.logout(tester);
  });
}
