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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class DepartmentTest {
  /// filter the list without opening a row; [CommonTest.doNewSearch] also taps
  /// the found row which would open its dialog
  static Future<void> search(WidgetTester tester, String searchString) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  static Future<void> selectDepartments(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/hr/departments', 'DepartmentList');
  }

  static Future<void> addDepartments(
    WidgetTester tester,
    List<Department> departments,
  ) async {
    for (final department in departments) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.enterText(tester, 'name', department.name);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'item0');
    }
    await checkDepartments(tester, departments);
  }

  static Future<void> updateDepartment(
    WidgetTester tester,
    String oldName,
    Department department,
  ) async {
    await search(tester, oldName);
    await CommonTest.tapByKey(tester, 'item0');
    await CommonTest.waitForKey(tester, 'DepartmentDialog');
    await CommonTest.enterText(tester, 'name', department.name);
    if (department.managerName != null) {
      await CommonTest.selectDropDown(
        tester,
        'manager',
        department.managerName!,
      );
    }
    await CommonTest.tapByKey(tester, 'update');
    await CommonTest.waitForKey(tester, 'item0');
  }

  static Future<void> checkDepartments(
    WidgetTester tester,
    List<Department> departments,
  ) async {
    for (final department in departments) {
      await search(tester, department.name);
      expect(
        CommonTest.getTextField('name0'),
        contains(department.name),
        reason: 'department ${department.name} should be in the list',
      );
      if (department.managerName != null) {
        expect(
          CommonTest.getTextField('manager0'),
          contains(department.managerName!),
        );
      }
    }
  }

  static Future<void> deleteDepartment(WidgetTester tester, String name) async {
    await search(tester, name);
    await CommonTest.tapByKey(tester, 'delete0');
    await CommonTest.tapByKey(tester, 'continue');
    await CommonTest.waitForSnackbarToGo(tester);
  }
}
