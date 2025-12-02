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

class ContentPlanTest {
  static Future<void> selectContentPlans(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/contentPlans',
      'ContentPlanList',
      null,
    );
  }

  static Future<void> addContentPlans(
    WidgetTester tester,
    List<ContentPlan> contentPlans,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
        test.copyWith(contentPlans: contentPlans));
    await enterContentPlanData(tester);
  }

  static Future<void> updateContentPlans(
    WidgetTester tester,
    List<ContentPlan> newContentPlans,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<ContentPlan> updatedContentPlans = [];
    for (int x = 0; x < newContentPlans.length; x++) {
      updatedContentPlans.add(
        newContentPlans[x].copyWith(
          planId: old.contentPlans[x].planId,
          pseudoId: old.contentPlans[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
        old.copyWith(contentPlans: updatedContentPlans));
    await enterContentPlanData(tester);
  }

  static Future<void> deleteContentPlans(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.contentPlans.length;
    expect(
      find.byKey(const Key('contentPlanItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete0',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm0',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('contentPlanItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(contentPlans: test.contentPlans.sublist(1, count)),
    );
  }

  /// Custom search for content plans - opens the search dialog and finds a content plan by ID
  static Future<void> doContentPlanSearch(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.tapByKey(tester, 'search');
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.tapByKey(tester, 'contentPlanSearchItem0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterContentPlanData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<ContentPlan> newContentPlans = [];

    for (ContentPlan contentPlan in test.contentPlans) {
      if (contentPlan.pseudoId == null) {
        // Add new content plan
        await CommonTest.tapByKey(tester, 'addNewContentPlan');
      } else {
        // Update existing content plan - use custom search
        await doContentPlanSearch(tester, searchString: contentPlan.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(contentPlan.pseudoId!),
          true,
        );
      }

      // Check for the detail screen (key varies based on pseudoId)
      final expectedKey = contentPlan.pseudoId == null
          ? 'ContentPlanDetailnull'
          : 'ContentPlanDetail${contentPlan.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      // Enter content plan info
      if (contentPlan.theme != null) {
        await CommonTest.enterText(tester, 'theme', contentPlan.theme!);
      }

      // Select the first available persona from the dropdown
      // The personas are preloaded via testData in the test runner
      await CommonTest.selectDropDown(tester, 'personaId', 'Alex Johnson');

      // Save the content plan
      await CommonTest.dragUntil(
        tester,
        key: 'contentPlanDetailSave',
        listViewName: 'contentPlanDetailListView',
      );
      await CommonTest.tapByKey(
        tester,
        'contentPlanDetailSave',
        seconds: CommonTest.waitTime,
      );

      // Get allocated ID for new content plans
      if (contentPlan.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'item0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        contentPlan = contentPlan.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newContentPlans.add(contentPlan);
    }

    await PersistFunctions.persistTest(
        test.copyWith(contentPlans: newContentPlans));
  }

  static Future<void> checkContentPlans(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (ContentPlan contentPlan in test.contentPlans) {
      await doContentPlanSearch(tester, searchString: contentPlan.pseudoId!);

      // Check detail - the dialog key is ContentPlanDetail${pseudoId}
      expect(find.byKey(Key('ContentPlanDetail${contentPlan.pseudoId}')),
          findsOneWidget);

      if (contentPlan.theme != null) {
        expect(CommonTest.getTextFormField('theme'), equals(contentPlan.theme));
      }

      // Verify persona is selected - the dropdown should contain "Alex Johnson"
      expect(find.textContaining('Alex Johnson'), findsOneWidget);

      await CommonTest.tapByKey(tester, 'cancel');
    }
  }
}
