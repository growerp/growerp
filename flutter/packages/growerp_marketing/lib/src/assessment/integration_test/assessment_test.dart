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

class AssessmentTest {
  static Future<void> selectAssessments(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/assessments',
      'AssessmentList',
      null,
    );
  }

  static Future<void> addAssessments(
    WidgetTester tester,
    List<Assessment> assessments,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(assessments: assessments));
    await enterAssessmentData(tester);
  }

  static Future<void> updateAssessments(
    WidgetTester tester,
    List<Assessment> newAssessments,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<Assessment> updatedAssessments = [];
    for (int x = 0; x < newAssessments.length; x++) {
      updatedAssessments.add(
        newAssessments[x].copyWith(
          pseudoId: old.assessments[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
      old.copyWith(assessments: updatedAssessments),
    );
    await enterAssessmentData(tester);
  }

  static Future<void> deleteAssessments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.assessments.length;
    expect(
      find.byKey(const Key('assessmentItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('assessmentItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(assessments: test.assessments.sublist(0, count - 1)),
    );
  }

  static Future<void> enterAssessmentData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Assessment> newAssessments = [];

    for (Assessment assessment in test.assessments) {
      if (assessment.pseudoId == null) {
        // Add new assessment
        await CommonTest.tapByKey(tester, 'addNewAssessment');
      } else {
        // Update existing assessment
        await CommonTest.doNewSearch(tester,
            searchString: assessment.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(assessment.pseudoId!),
          true,
        );
      }

      expect(find.byKey(Key('AssessmentDetail${assessment.pseudoId}')),
          findsOneWidget);

      // Enter basic info
      await CommonTest.enterText(
        tester,
        'name',
        assessment.assessmentName,
      );

      if (assessment.description != null) {
        await CommonTest.enterText(
          tester,
          'description',
          assessment.description!,
        );
      }

      await CommonTest.enterDropDown(tester, 'status', assessment.status);

      // Save the assessment
      await CommonTest.dragUntil(
        tester,
        key: 'assessmentDetailSave',
        listViewName: 'assessmentDetailListView',
      );
      await CommonTest.tapByKey(
        tester,
        'assessmentDetailSave',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.waitForSnackbarToGo(tester);

      // Get allocated ID for new assessments
      if (assessment.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'name0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        assessment = assessment.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newAssessments.add(assessment);
    }

    await clearSearch(tester);
    await PersistFunctions.persistTest(
      test.copyWith(assessments: newAssessments),
    );
  }

  /// Clear the search field to show all items
  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> checkAssessments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (Assessment assessment in test.assessments) {
      await CommonTest.doNewSearch(
        tester,
        searchString: assessment.pseudoId!,
      );

      // Check detail
      expect(find.byKey(Key('AssessmentDetail${assessment.pseudoId}')),
          findsOneWidget);
      expect(
        CommonTest.getTextFormField('name'),
        equals(assessment.assessmentName),
      );

      if (assessment.description != null) {
        expect(
          CommonTest.getTextFormField('description'),
          equals(assessment.description!),
        );
      }

      expect(
        CommonTest.getDropdown('status'),
        equals(assessment.status),
      );

      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }
}
