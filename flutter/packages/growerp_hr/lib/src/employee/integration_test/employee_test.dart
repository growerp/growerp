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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class EmployeeTest {
  /// scroll a field of the (long) employee dialog into view: a field below the
  /// fold is in the tree but does not hit test
  static Future<void> _show(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  /// filter the list without opening a row; [CommonTest.doNewSearch] also taps
  /// the found row which would open its dialog
  static Future<void> search(WidgetTester tester, String searchString) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  static Future<void> selectEmployees(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/hr/employees', 'EmployeeList');
  }

  static Future<void> addEmployees(
    WidgetTester tester,
    List<Employee> employees,
  ) async {
    for (final employee in employees) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.waitForKey(tester, 'EmployeeDialog');
      await CommonTest.enterText(tester, 'firstName', employee.firstName);
      await CommonTest.enterText(tester, 'lastName', employee.lastName);
      await CommonTest.enterText(tester, 'email', employee.email ?? '');
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
      await CommonTest.waitForKey(tester, 'item0');
    }
    await checkEmployees(tester, employees);
  }

  static Future<void> checkEmployees(
    WidgetTester tester,
    List<Employee> employees,
  ) async {
    for (final employee in employees) {
      await search(tester, employee.lastName);
      expect(
        CommonTest.getTextField('name0'),
        contains(employee.firstName),
        reason: 'employee ${employee.name} should be in the list',
      );
      if (employee.jobTitle != null) {
        expect(CommonTest.getTextField('jobTitle0'), employee.jobTitle);
      }
      if (employee.department != null) {
        expect(CommonTest.getTextField('department0'), employee.department);
      }
      if (employee.status != null) {
        expect(CommonTest.getTextField('status0'), employee.status!.name);
      }
    }
  }

  /// open the employee found with [lastName] and fill in the HR fields
  static Future<void> updateEmployee(
    WidgetTester tester,
    String lastName,
    Employee employee, {
    String? annualAllowance,
  }) async {
    await search(tester, lastName);
    await CommonTest.tapByKey(tester, 'item0');
    await CommonTest.waitForKey(tester, 'EmployeeDialog');
    if (employee.jobTitle != null) {
      await _show(tester, 'jobTitle');
      await CommonTest.selectDropDown(tester, 'jobTitle', employee.jobTitle!);
    }
    if (employee.department != null) {
      await _show(tester, 'department');
      await CommonTest.selectDropDown(
        tester,
        'department',
        employee.department!,
      );
    }
    if (employee.hireDate != null) {
      await _show(tester, 'hireDate');
      await CommonTest.enterDate(
        tester,
        'hireDate',
        employee.hireDate!,
        usDate: true,
      );
    }
    if (employee.status != null) {
      await _show(tester, 'status');
      await CommonTest.selectDropDown(tester, 'status', employee.status!.name);
    }
    if (annualAllowance != null) {
      await _show(tester, 'allowanceAnnual');
      await CommonTest.enterText(tester, 'allowanceAnnual', annualAllowance);
    }
    await _show(tester, 'update');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    await CommonTest.waitForKey(tester, 'item0');
  }

  /// tick a checklist item of the employee found with [lastName]
  static Future<void> tickOnboardingTask(
    WidgetTester tester,
    String lastName,
    int taskIndex,
  ) async {
    await search(tester, lastName);
    await CommonTest.tapByKey(tester, 'item0');
    await CommonTest.waitForKey(tester, 'EmployeeDialog');
    await _show(tester, 'onboardingTask$taskIndex');
    await CommonTest.tapByKey(tester, 'onboardingTask$taskIndex', seconds: 3);
    await CommonTest.tapByKey(tester, 'cancel');
  }
}
