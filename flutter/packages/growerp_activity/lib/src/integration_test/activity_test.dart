/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class ActivityTest {
  static Future<void> selectActivities(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/todos', 'ActivityList');
  }

  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> addActivities(
    WidgetTester tester,
    List<Activity> activities, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.activities.isEmpty) {
      // not yet created
      await enterActivityData(tester, activities);
      await PersistFunctions.persistTest(test.copyWith(activities: activities));
    }
    if (check) {
      await PersistFunctions.persistTest(
        test.copyWith(
          activities: await checkActivityDetail(tester, activities),
        ),
      );
    }
  }

  static Future<void> enterActivityData(
    WidgetTester tester,
    List<Activity> activities,
  ) async {
    for (Activity activity in activities) {
      if (activity.activityId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        // Find the row displaying this activityId and tap it
        bool found = false;
        for (int i = 0; i < 20; i++) {
          if (!tester.any(find.byKey(Key('id$i')))) break;
          if (CommonTest.getTextField('id$i') == activity.activityId) {
            await tester.ensureVisible(find.byKey(Key('id$i')));
            await tester.tap(find.byKey(Key('name$i')));
            await tester.pump();
            await tester.pump(const Duration(seconds: CommonTest.waitTime));
            await tester.pumpAndSettle(
              const Duration(seconds: CommonTest.waitTime),
            );
            found = true;
            break;
          }
        }
        if (!found) continue;
      }
      await CommonTest.checkWidgetKey(tester, 'ActivityDialog');
      await CommonTest.tapByKey(
        tester,
        'name',
      ); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', activity.activityName);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'description', activity.description);
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Activity>> checkActivityDetail(
    WidgetTester tester,
    List<Activity> activities,
  ) async {
    // Clear search to show all activities
    await clearSearch(tester);

    // Build a map from activityName → activityId by iterating visible rows
    final Map<String, String> nameToId = {};
    for (int i = 0; i < activities.length; i++) {
      await tester.ensureVisible(find.byKey(Key('name$i')));
      await tester.tap(find.byKey(Key('name$i')));
      await tester.pump();
      await tester.pump(const Duration(seconds: CommonTest.waitTime));
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
      expect(find.byKey(const Key('ActivityDialog')), findsOneWidget);
      final displayedName = CommonTest.getTextFormField('name');
      final id = CommonTest.getTextField('topHeader').split('#')[1];
      nameToId[displayedName] = id;
      await CommonTest.tapByKey(tester, 'cancel');
    }

    // Match each expected activity to the ID found in the dialog
    return activities
        .map((a) => a.copyWith(activityId: nameToId[a.activityName] ?? ''))
        .toList();
  }

  static Future<void> deleteLastActivity(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.activities.length;
    // Count visible rows via delete-button keys
    int visibleCount = 0;
    while (tester.any(find.byKey(Key('delete$visibleCount')))) visibleCount++;
    expect(visibleCount, count);
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    // Verify one fewer row
    int newCount = 0;
    while (tester.any(find.byKey(Key('delete$newCount')))) newCount++;
    expect(newCount, count - 1);
    await PersistFunctions.persistTest(
      test.copyWith(
        activities: test.activities.sublist(0, test.activities.length - 1),
      ),
    );
  }

  static Future<void> updateActivities(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.activities[0].activityName != activities[0].activityName) return;
    List<Activity> updActivities = [];
    for (Activity activity in test.activities) {
      updActivities.add(
        activity.copyWith(
          activityName: '${activity.activityName}u',
          description: '${activity.description}u',
        ),
      );
    }
    await enterActivityData(tester, updActivities);
    await checkActivityDetail(tester, updActivities);
    await PersistFunctions.persistTest(
      test.copyWith(activities: updActivities),
    );
  }
}
