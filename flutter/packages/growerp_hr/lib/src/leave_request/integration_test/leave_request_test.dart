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

class LeaveRequestTest {
  /// scroll a field of the dialog into view: a field below the fold is in the
  /// tree but does not hit test
  static Future<void> _show(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  static Future<void> selectLeaveRequests(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/hr/leave', 'LeaveRequestList');
  }

  /// add leave requests; when the employee name is filled in the request is
  /// entered for that employee (admin), else for the logged in user
  static Future<void> addLeaveRequests(
    WidgetTester tester,
    List<LeaveRequest> leaveRequests,
  ) async {
    for (final leaveRequest in leaveRequests) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.waitForKey(tester, 'LeaveRequestDialog');
      if (leaveRequest.employeeName != null) {
        await CommonTest.selectDropDown(
          tester,
          'employee',
          leaveRequest.employeeName!,
        );
      }
      await CommonTest.selectDropDown(
        tester,
        'leaveType',
        (leaveRequest.leaveType ?? LeaveType.annual).name,
      );
      await _show(tester, 'fromDate');
      await CommonTest.enterDate(
        tester,
        'fromDate',
        leaveRequest.fromDate!,
        usDate: true,
      );
      await _show(tester, 'thruDate');
      await CommonTest.enterDate(
        tester,
        'thruDate',
        leaveRequest.thruDate!,
        usDate: true,
      );
      if (leaveRequest.reason != null) {
        await _show(tester, 'reason');
        await CommonTest.enterText(tester, 'reason', leaveRequest.reason!);
      }
      await _show(tester, 'update');
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  static Future<void> setStatus(
    WidgetTester tester,
    int index,
    LeaveStatus status,
  ) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'LeaveRequestDialog');
    final key = switch (status) {
      LeaveStatus.approved => 'approve',
      LeaveStatus.rejected => 'reject',
      _ => 'cancelRequest',
    };
    await _show(tester, key);
    await CommonTest.tapByKey(tester, switch (status) {
      LeaveStatus.approved => 'approve',
      LeaveStatus.rejected => 'reject',
      _ => 'cancelRequest',
    }, seconds: 3);
    await CommonTest.waitForKey(tester, 'item$index');
  }

  static Future<void> checkLeaveRequest(
    WidgetTester tester,
    int index, {
    LeaveStatus? status,
    String? days,
    String? employeeName,
  }) async {
    await CommonTest.waitForKey(tester, 'status$index');
    if (status != null) {
      expect(
        CommonTest.getTextField('status$index'),
        status.name,
        reason: 'leave request $index should have status ${status.name}',
      );
    }
    if (days != null) {
      expect(CommonTest.getTextField('days$index'), days);
    }
    if (employeeName != null) {
      expect(CommonTest.getTextField('employee$index'), contains(employeeName));
    }
  }
}
