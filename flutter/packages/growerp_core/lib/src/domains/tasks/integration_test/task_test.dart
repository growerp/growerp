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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../integration_test.dart';

class TaskTest {
  static Future<void> createNewTask(WidgetTester tester, Task task) async {
    await showNewDetail(tester);
    await enterTasktaskName(tester, task);
    await pressCreate(tester);
  }

  static Future<void> checkDataInListForDemoData(
      WidgetTester tester, Task task) async {
    expect(CommonTest.getTextField('name0'), task.taskName);
  }

  static Future<void> enterTaskDemoDataAndSave(WidgetTester tester) async {}

  static Future<void> enterTasktaskName(WidgetTester tester, Task task) async {
    await CommonTest.enterText(tester, 'taskName', task.taskName!);
  }

  static Future<void> pressCreate(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'update', seconds: 5);
  }

  static Future<void> showNewDetail(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'addNew');
  }

  static Future<void> showTaskList(WidgetTester tester) async {
    await CommonTest.selectMainMenu(tester, "tap/tasks");
  }
}
