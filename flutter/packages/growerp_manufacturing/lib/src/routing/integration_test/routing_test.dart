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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class RoutingTest {
  static Future<void> selectRoutings(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/manufacturing/routing',
      'RoutingList',
    );
  }

  static Future<void> addRoutings(
    WidgetTester tester,
    List<Routing> routings,
  ) async {
    await enterRoutingData(tester, routings);
    await checkRoutings(tester, routings);
  }

  static Future<void> enterRoutingData(
    WidgetTester tester,
    List<Routing> routings,
  ) async {
    for (Routing routing in routings) {
      if (routing.routingId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: routing.routingName ?? '',
        );
        await CommonTest.tapByKey(tester, 'item0');
      }
      if (routing.routingName != null) {
        await CommonTest.enterText(tester, 'routingName', routing.routingName!);
      }
      if (routing.description != null) {
        await CommonTest.enterText(
            tester, 'description', routing.description!);
      }
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  static Future<void> checkRoutings(
    WidgetTester tester,
    List<Routing> routings,
  ) async {
    for (int i = 0; i < routings.length; i++) {
      await CommonTest.waitForKey(tester, 'routingName$i');
      expect(
        CommonTest.getTextField('routingName$i'),
        contains(routings[i].routingName ?? ''),
        reason: 'Routing $i should display expected name',
      );
    }
  }

  static Future<void> deleteRouting(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'delete$index');
    await CommonTest.tapByKey(tester, 'continue');
  }

  static Future<void> openRouting(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'RoutingDialog');
  }

  /// Add routing tasks to the currently open RoutingDialog.
  static Future<void> addRoutingTasks(
    WidgetTester tester,
    List<RoutingTask> tasks,
  ) async {
    for (final task in tasks) {
      await CommonTest.tapByKey(tester, 'addTask');
      await CommonTest.waitForKey(tester, 'RoutingTaskDialog');
      await CommonTest.enterText(tester, 'taskName', task.taskName ?? '');
      if (task.sequenceNum != null) {
        await CommonTest.enterText(
            tester, 'sequenceNum', task.sequenceNum.toString());
      }
      if (task.estimatedWorkTime != null) {
        await CommonTest.enterText(
            tester, 'estimatedWorkTime', task.estimatedWorkTime.toString());
      }
      if (task.workCenterName != null) {
        await CommonTest.enterText(
            tester, 'workCenterName', task.workCenterName!);
      }
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'RoutingDialog');
    }
  }

  /// Verify task names in the currently open RoutingDialog.
  static Future<void> checkRoutingTasks(
    WidgetTester tester,
    List<RoutingTask> tasks,
  ) async {
    for (int i = 0; i < tasks.length; i++) {
      await CommonTest.waitForKey(tester, 'taskItemName$i');
      if (tasks[i].taskName != null) {
        expect(
          CommonTest.getTextField('taskItemName$i'),
          contains(tasks[i].taskName!),
          reason: 'Task $i should display expected name',
        );
      }
    }
  }

  /// Tap the delete button for the task at [index] in the currently open
  /// RoutingDialog. Does not confirm — the delete is immediate.
  static Future<void> deleteRoutingTask(
      WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'deleteTaskItem$index');
    await CommonTest.waitForKey(tester, 'RoutingDialog');
  }
}
