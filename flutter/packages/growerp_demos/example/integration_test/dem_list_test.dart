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
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_demos/growerp_demos.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demos_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('Demo list shows all registered demos', (tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createDemosExampleRouter(),
      demosMenuConfig,
      delegates,
      blocProviders: getDemosBlocProviders(restClient),
      restClient: restClient,
      title: 'GrowERP Demos',
      clear: true,
      widgetRegistrations: demosWidgetRegistrations,
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Navigate to the Demos screen
    await CommonTest.selectOption(tester, '/demos', 'DemoList');

    // Wait for async progress load (_loaded becomes true and ListView appears)
    for (var i = 0; i < 20; i++) {
      if (find.byKey(const Key('DemoListView')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 200));
    }
    final listFinder = find.byKey(const Key('DemoListView'));

    // All registered demos should be visible and say "Not started"
    for (final demo in registeredDemos) {
      final titleFinder = find.text(demo.title);
      await tester.dragUntilVisible(
        titleFinder,
        listFinder,
        const Offset(0, -300),
      );
      expect(titleFinder, findsOneWidget);
      expect(find.text('Not started'), findsWidgets);
    }

    // Scroll back up to the first demo before tapping
    final firstDemoFinder = find.text(registeredDemos.first.title);
    await tester.dragUntilVisible(
      firstDemoFinder,
      listFinder,
      const Offset(0, 300),
    );

    // Tapping the first demo opens the runner. Tap the full-width "open" button
    // (keyed) rather than the title text: on narrow mobile layouts the title's
    // center can sit off-screen, so a tap on it misses and never navigates.
    final openButtonFinder = find.byKey(
      Key('openDemo_${registeredDemos.first.title}'),
    );
    await tester.ensureVisible(openButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(openButtonFinder);
    await tester.pumpAndSettle();

    // The runner should show "Step 1 of ..." (appears in both progress label and button)
    expect(
      find.textContaining('Step 1 of'),
      findsAtLeastNWidgets(1),
    );

    // Go back to the demo list
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Should still show the demo list
    expect(find.text(registeredDemos.first.title), findsOneWidget);
  });
}
