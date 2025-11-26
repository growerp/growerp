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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class QuestionTest {
  static Future<void> selectQuestions(
    WidgetTester tester,
    String assessmentPseudoId,
  ) async {
    // Search for the assessment
    await CommonTest.doNewSearch(tester, searchString: assessmentPseudoId);
    await tester.pumpAndSettle();

    // The assessment detail should now be open
    // Click on Questions FAB
    await CommonTest.tapByKey(tester, 'questions',
        seconds: CommonTest.waitTime);
    await tester.pumpAndSettle();
  }

  static Future<void> addQuestions(
    WidgetTester tester,
    List<AssessmentQuestion> questions,
  ) async {
    // Add questions to the current assessment
    for (AssessmentQuestion question in questions) {
      // Add new question
      await CommonTest.tapByKey(tester, 'addQuestion');
      await tester.pumpAndSettle();

      // Enter question text
      await CommonTest.enterText(
        tester,
        'questionText',
        question.questionText!,
      );

      // Enter question description if provided
      if (question.questionDescription != null) {
        await CommonTest.enterText(
          tester,
          'questionDescription',
          question.questionDescription!,
        );
      }

      // Select question type
      await CommonTest.enterDropDown(
        tester,
        'questionType',
        question.questionType!,
      );

      // Set required checkbox
      if (question.isRequired == true) {
        await CommonTest.tapByKey(tester, 'isRequired');
      }

      // Add options if question type needs them
      if (question.options != null && question.options!.isNotEmpty) {
        for (int i = 0; i < question.options!.length; i++) {
          final option = question.options![i];

          // Scroll to the add option button
          await CommonTest.dragUntil(
            tester,
            key: 'addOption',
            listViewName: 'questionDetailListView',
          );

          // Add option
          await CommonTest.tapByKey(tester, 'addOption');
          await tester.pumpAndSettle();

          // After adding an option, the key will be based on the current number of options
          // The new option will have index i (0-based)
          final optionKey = 'new_$i';

          // Scroll to the option fields
          await tester.pumpAndSettle();

          // Enter option text
          await CommonTest.enterText(
            tester,
            '${optionKey}_text',
            option.optionText!,
          );

          // Enter score
          await CommonTest.enterText(
            tester,
            '${optionKey}_score',
            option.optionScore.toString(),
          );
        }
      }

      // Save the question
      await CommonTest.dragUntil(
        tester,
        key: 'save',
        listViewName: 'questionDetailListView',
      );
      await CommonTest.tapByKey(
        tester,
        'save',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<void> checkQuestions(WidgetTester tester) async {
    // Questions are stored in the assessment model, not in SaveTest
    // Verify question items are visible in the list
    expect(
      find.byKey(const Key('questionItem'), skipOffstage: false),
      findsWidgets,
      reason: 'No questions found in assessment',
    );

    // Tap on first question to verify details
    await CommonTest.tapByKey(
      tester,
      'question0',
      seconds: CommonTest.waitTime,
    );

    // Verify question text field exists
    expect(
      find.byKey(const Key('questionText')),
      findsWidgets,
      reason: 'Question text field not found',
    );

    // Close the dialog
    await CommonTest.tapByKey(tester, 'cancel');
    await tester.pumpAndSettle();
  }

  static Future<void> deleteLastQuestion(WidgetTester tester) async {
    // Find current count of questions in the UI
    final questionCount = find.byKey(
      const Key('questionItem'),
      skipOffstage: false,
    );

    // Get the count
    final count = questionCount.evaluate().length;

    // Verify count
    expect(
      questionCount,
      findsNWidgets(count),
    );

    // Delete last question
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    // confirm deletion
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm',
      seconds: CommonTest.waitTime,
    );
    // Verify deletion
    expect(
      find.byKey(const Key('questionItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
  }
}
