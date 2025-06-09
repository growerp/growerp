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
    await CommonTest.selectOption(tester, '/', 'ActivityList');
  }

  static Future<void> addActivities(
      WidgetTester tester, List<Activity> activities,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.activities.isEmpty) {
      // not yet created
      await enterActivityData(tester, activities);
      await PersistFunctions.persistTest(test.copyWith(activities: activities));
    }
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          activities: await checkActivityDetail(tester, activities)));
    }
  }

  static Future<void> enterActivityData(
      WidgetTester tester, List<Activity> activities) async {
    for (Activity activity in activities) {
      if (activity.activityId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: activity.activityId);
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            activity.activityId);
      }
      await CommonTest.checkWidgetKey(tester, 'ActivityDialog');
      await CommonTest.tapByKey(
          tester, 'name'); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', activity.activityName);
      await CommonTest.drag(tester);
      await CommonTest.enterText(tester, 'description', activity.description);
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Activity>> checkActivityDetail(
      WidgetTester tester, List<Activity> activities) async {
    List<Activity> newActivities = [];
    for (Activity activity in activities) {
      // list
      for (final (index, _) in activities.indexed) {
        if (CommonTest.getTextField('id$index') == activity.pseudoId) {
          expect(CommonTest.getTextField('name$index'),
              equals(activity.activityName));
          expect(CommonTest.getTextField('products$index'), equals('0'));
        }
      }
      await CommonTest.doNewSearch(tester,
          searchString: activity.activityName, seconds: CommonTest.waitTime);
      // detail
      await CommonTest.tapByKey(tester, 'name0');
      expect(find.byKey(const Key('ActivityDialog')), findsOneWidget);
      expect(
          CommonTest.getTextFormField('name'), equals(activity.activityName));
      expect(CommonTest.getTextFormField('description'),
          equals(activity.description));
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newActivities.add(activity.copyWith(activityId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newActivities;
  }

  static Future<void> deleteLastActivity(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.activities.length;
    expect(find.byKey(const Key('activityItem')),
        findsNWidgets(count)); // initial admin
    await CommonTest.tapByKey(tester, 'delete${count - 1}',
        seconds: CommonTest.waitTime);
    // replacement for refresh...
    expect(find.byKey(const Key('activityItem')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(test.copyWith(
        activities: test.activities.sublist(0, test.activities.length - 1)));
  }

  static Future<void> updateActivities(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.activities[0].activityName != activities[0].activityName) return;
    List<Activity> updActivities = [];
    for (Activity activity in test.activities) {
      updActivities.add(activity.copyWith(
        activityName: '${activity.activityName}u',
        description: '${activity.description}u',
      ));
    }
    await enterActivityData(tester, updActivities);
    await checkActivityDetail(tester, updActivities);
    await PersistFunctions.persistTest(
        test.copyWith(activities: updActivities));
  }
}
