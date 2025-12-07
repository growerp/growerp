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

import 'package:growerp_marketing_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_marketing/src/test_data.dart' as assessment_data;
import 'package:growerp_marketing/src/landing_page/integration_test/landing_page_test.dart';
import 'package:growerp_marketing/src/assessment/integration_test/assessment_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP take assessment test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createMarketingExampleRouter(),
      marketingMenuConfig,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
      ),
      title: 'GrowERP take assessment test',
      clear: true,
    );

    // Step 1: Create company and admin user
    await CommonTest.createCompanyAndAdmin(tester);

    // Step 2: Create a landing page with assessment
    await LandingPageTest.selectLandingPages(tester);
    await LandingPageTest.addLandingPages(
      tester,
      assessment_data.landingPages.sublist(0, 1),
    );

    // Step 3: Create an assessment
    await AssessmentTest.selectAssessments(tester);
    await AssessmentTest.addAssessments(
      tester,
      assessment_data.assessments.sublist(0, 1),
    );

    // Step 4: Navigate to Take Assessment menu
    await _selectTakeAssessment(tester);

    // Step 5: Verify assessment list is displayed
    await _checkAssessmentListDisplayed(tester);

    // Step 6: Select an assessment to take
    await _selectAssessmentToTake(tester);

    // Step 7: Verify assessment flow screen is displayed
    await _verifyAssessmentFlowScreen(tester);

    // Step 8: Cleanup
    await CommonTest.logout(tester);
  });

  testWidgets('''GrowERP take assessment - no assessments available''', (
    tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createMarketingExampleRouter(),
      marketingMenuConfig,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
      ),
      title: 'GrowERP take assessment - empty test',
      clear: true,
    );

    // Step 1: Create company and admin user
    await CommonTest.createCompanyAndAdmin(tester);

    // Step 2: Navigate to Take Assessment menu without creating assessments
    await _selectTakeAssessment(tester);

    // Step 3: Verify empty state is displayed
    await _verifyEmptyState(tester);

    // Step 4: Cleanup
    await CommonTest.logout(tester);
  });
}

// =============== Helper Methods ===============

/// Navigate to Take Assessment menu
Future<void> _selectTakeAssessment(WidgetTester tester) async {
  await CommonTest.selectOption(
    tester,
    '/takeAssessment',
    'TakeAssessmentMenu',
    null,
  );
}

/// Verify assessment list is displayed with available assessments
Future<void> _checkAssessmentListDisplayed(WidgetTester tester) async {
  // Wait for assessments to load
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Check for assessment list items
  expect(
    find.byType(Card),
    findsAtLeastNWidgets(1),
    reason: 'Should display at least one assessment card',
  );

  // Verify assessment card contains expected elements
  expect(
    find.byIcon(Icons.quiz),
    findsAtLeastNWidgets(1),
    reason: 'Should display quiz icon for assessments',
  );

  expect(
    find.byIcon(Icons.arrow_forward_ios),
    findsAtLeastNWidgets(1),
    reason: 'Should display navigation arrow',
  );
}

/// Select the first assessment to take
Future<void> _selectAssessmentToTake(WidgetTester tester) async {
  // Find and tap the first assessment card
  final firstCard = find.byType(Card).first;
  await tester.tap(firstCard);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Verify assessment flow screen is displayed
Future<void> _verifyAssessmentFlowScreen(WidgetTester tester) async {
  // The assessment flow screen should be displayed
  // We can verify by checking if we've navigated away from the assessment list
  expect(
    find.text('Select an Assessment to Take'),
    findsNothing,
    reason: 'Should navigate away from assessment list',
  );

  // The screen should show the LandingPageAssessmentFlowScreen
  // which contains either the landing page or the assessment
  expect(
    find.byType(Scaffold),
    findsAtLeastNWidgets(1),
    reason: 'Assessment flow screen should be displayed',
  );
}

/// Verify empty state when no assessments are available
Future<void> _verifyEmptyState(WidgetTester tester) async {
  // Wait for state to load
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Check for empty state message
  expect(
    find.text('No assessments available'),
    findsOneWidget,
    reason: 'Should display empty state message',
  );

  expect(
    find.byIcon(Icons.assessment_outlined),
    findsOneWidget,
    reason: 'Should display assessment icon in empty state',
  );

  expect(
    find.text('Create an assessment first in the Assessments menu'),
    findsOneWidget,
    reason: 'Should display helpful message',
  );
}
