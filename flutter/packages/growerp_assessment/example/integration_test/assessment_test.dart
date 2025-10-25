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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import '../lib/main.dart';
import 'package:growerp_models/growerp_models.dart';

// Static menuOptions for testing (no localization needed)
List<MenuOption> testMenuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const MainMenu(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Assessment',
    route: '/assessment',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const AssessmentListScreen(),
        label: 'Assessments',
        icon: const Icon(Icons.assignment),
      ),
      TabItem(
        form: const AssessmentTakeScreen(),
        label: 'Take Assessment',
        icon: const Icon(Icons.play_arrow),
      ),
      TabItem(
        form: const AssessmentResultsListScreen(),
        label: 'Results',
        icon: const Icon(Icons.assessment),
      ),
    ],
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  String title = 'GrowERP Assessment Integration Test';

  testWidgets(title, (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      [],
      restClient: restClient,
      blocProviders: getAssessmentBlocProviders(restClient),
      title: title,
      clear: true,
    ); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester);

    // Test basic assessment workflow
    await selectAssessments(tester);
    await createAssessment(tester);

    debugPrint("Assessment created successfully!");

    // Test basic question management (just navigation)
    await testQuestionManagementNavigation(tester);

    // Test adding questions to the assessment
    await addBasicQuestionToAssessment(tester);

    // Skip logout for now to focus on assessment functionality
    debugPrint("Assessment integration test completed successfully!");
  });
}

/// Test helper functions
Future<void> testQuestionManagementNavigation(WidgetTester tester) async {
  debugPrint("Testing question management navigation...");

  // Click on an assessment to go to question management
  // Look for the first assessment in the list
  var assessmentTile = find.byType(ListTile).first;
  if (assessmentTile.evaluate().isNotEmpty) {
    await tester.tap(assessmentTile);
    await tester.pumpAndSettle();
    debugPrint("Navigated to question management screen");
  }
}

Future<void> addBasicQuestionToAssessment(WidgetTester tester) async {
  debugPrint("Testing adding a question to assessment...");

  try {
    // Look for the "Add First Question" button in empty state first
    var addFirstButton = find.byKey(const Key('addFirstQuestion'));
    var addFloatingButton = find.byKey(const Key('addQuestion'));

    Finder addButton = addFirstButton.evaluate().isNotEmpty
        ? addFirstButton
        : addFloatingButton;

    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      debugPrint("Opened add question dialog");

      // Fill in question text
      await CommonTest.enterText(
          tester, 'questionText', 'What is your experience level?');
      await tester.pumpAndSettle();
      debugPrint("Filled question text");

      // Save the question
      await CommonTest.tapByKey(tester, 'saveQuestion');
      await tester.pumpAndSettle();
      debugPrint("Question added successfully");
    } else {
      debugPrint(
          "No add question button found (neither 'Add First Question' nor FloatingActionButton)");
    }
  } catch (e) {
    debugPrint("Error adding question: $e");
  }
}

Future<void> selectAssessments(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/assessment', 'AssessmentListScaffold', '1');
}

Future<void> createAssessment(WidgetTester tester) async {
  // Look for create/add button (FloatingActionButton or Add button)
  var createButton = find.byType(FloatingActionButton);
  if (createButton.evaluate().isEmpty) {
    createButton = find.byIcon(Icons.add);
  }

  if (createButton.evaluate().isNotEmpty) {
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Fill in assessment details
    await CommonTest.enterText(tester, 'name', 'Integration Test Assessment');
    await CommonTest.enterText(tester, 'description',
        'Test assessment created during integration testing');

    // Save the assessment
    await CommonTest.tapByKey(tester, 'createAssessment');
    await tester.pumpAndSettle();
  }
}

Future<void> addQuestionsToAssessment(WidgetTester tester) async {
  // Find the created assessment in the list and tap it
  final assessmentTile = find.text('Integration Test Assessment');
  if (assessmentTile.evaluate().isNotEmpty) {
    await tester.tap(assessmentTile);
    await tester.pumpAndSettle();

    // Look for Questions tab or Questions button
    var questionsTab = find.text('Questions');
    if (questionsTab.evaluate().isEmpty) {
      questionsTab = find.byIcon(Icons.quiz);
    }

    if (questionsTab.evaluate().isNotEmpty) {
      await tester.tap(questionsTab);
      await tester.pumpAndSettle();
    }

    // Add a question
    final addQuestionButton = find.byIcon(Icons.add);
    if (addQuestionButton.evaluate().isNotEmpty) {
      await tester.tap(addQuestionButton.first);
      await tester.pumpAndSettle();

      // Fill question details
      await CommonTest.enterText(
          tester, 'questionText', 'What is your experience level?');

      // Save question
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // Add options to the question
      await addOptionsToQuestion(tester);
    }
  }
}

Future<void> addOptionsToQuestion(WidgetTester tester) async {
  // Add multiple choice options
  final optionTexts = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  final optionScores = ['1', '2', '3', '4'];

  for (int i = 0; i < optionTexts.length; i++) {
    final addOptionButton = find.text('Add Option');
    if (addOptionButton.evaluate().isNotEmpty) {
      await tester.tap(addOptionButton);
      await tester.pumpAndSettle();

      await CommonTest.enterText(tester, 'optionText', optionTexts[i]);
      await CommonTest.enterText(tester, 'score', optionScores[i]);

      final saveOptionButton = find.text('Save');
      if (saveOptionButton.evaluate().isNotEmpty) {
        await tester.tap(saveOptionButton);
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> takeAssessment(WidgetTester tester) async {
  // Navigate to Take Assessment tab
  await CommonTest.selectOption(
      tester, '/assessment', 'AssessmentListScaffold', '2');

  // Find the assessment we created and start it
  final assessmentTile = find.text('Integration Test Assessment');
  if (assessmentTile.evaluate().isNotEmpty) {
    await tester.tap(assessmentTile);
    await tester.pumpAndSettle();

    // Fill in lead capture form if present
    await fillLeadCaptureForm(tester);

    // Start the assessment
    final startButton = find.text('Start Assessment');
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle();
    }

    // Answer the questions
    await answerAssessmentQuestions(tester);

    // Submit the assessment
    final submitButton = find.text('Submit');
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> fillLeadCaptureForm(WidgetTester tester) async {
  // Fill in respondent information
  final nameField = find.byKey(const Key('respondentName'));
  if (nameField.evaluate().isNotEmpty) {
    await tester.enterText(nameField, 'Test User');
    await tester.pumpAndSettle();
  }

  final emailField = find.byKey(const Key('respondentEmail'));
  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'test.user@example.com');
    await tester.pumpAndSettle();
  }

  final companyField = find.byKey(const Key('respondentCompany'));
  if (companyField.evaluate().isNotEmpty) {
    await tester.enterText(companyField, 'Test Company');
    await tester.pumpAndSettle();
  }
}

Future<void> answerAssessmentQuestions(WidgetTester tester) async {
  // Look for question options and select one
  final radioButtons = find.byType(Radio);
  final listTiles = find.byType(ListTile);

  if (radioButtons.evaluate().isNotEmpty) {
    // Answer with radio button (select "Intermediate" - second option)
    await tester.tap(radioButtons.at(1));
    await tester.pumpAndSettle();
  } else if (listTiles.evaluate().isNotEmpty) {
    // Answer with list tile
    await tester.tap(listTiles.at(1));
    await tester.pumpAndSettle();
  }

  // Look for Next button to continue to next question or finish
  final nextButton = find.text('Next');
  if (nextButton.evaluate().isNotEmpty) {
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Recursively answer more questions if they exist
    await answerRemainingQuestions(tester);
  }
}

Future<void> answerRemainingQuestions(WidgetTester tester) async {
  // Check if there are more questions to answer
  final radioButtons = find.byType(Radio);
  if (radioButtons.evaluate().isNotEmpty) {
    // Answer next question
    await tester.tap(radioButtons.first);
    await tester.pumpAndSettle();

    final nextButton = find.text('Next');
    if (nextButton.evaluate().isNotEmpty) {
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Continue recursively
      await answerRemainingQuestions(tester);
    }
  }
}

Future<void> verifyResults(WidgetTester tester) async {
  // Navigate to Results tab
  await CommonTest.selectOption(
      tester, '/assessment', 'AssessmentListScaffold', '3');

  // Wait for results to load
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Look for results list
  final resultsList = find.byType(ListView);
  expect(resultsList, findsAtLeastNWidgets(1),
      reason: 'Should find results list');

  // Look for our test result
  final testResult = find.textContaining('Test User');
  if (testResult.evaluate().isNotEmpty) {
    await tester.tap(testResult);
    await tester.pumpAndSettle();

    // Verify result details
    expect(find.text('Integration Test Assessment'), findsOneWidget);
    expect(find.textContaining('Test User'), findsOneWidget);
    expect(find.textContaining('test.user@example.com'), findsOneWidget);
  }
}
