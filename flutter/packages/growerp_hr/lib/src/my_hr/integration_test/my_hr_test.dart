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

class MyHrTest {
  static Future<void> selectMyHr(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/hr', 'MyHrView');
  }

  static Future<void> checkProfile(
    WidgetTester tester, {
    String? jobTitle,
    String? department,
    EmployeeStatus? status,
  }) async {
    await CommonTest.waitForKey(tester, 'myProfile');
    if (jobTitle != null) {
      expect(CommonTest.getTextField('myJobTitle'), contains(jobTitle));
    }
    if (department != null) {
      expect(CommonTest.getTextField('myDepartment'), contains(department));
    }
    if (status != null) {
      expect(CommonTest.getTextField('myStatus'), contains(status.name));
    }
  }

  static Future<void> checkBalance(
    WidgetTester tester,
    LeaveType leaveType,
    String usedOfAllowance,
  ) async {
    await CommonTest.waitForKey(tester, 'balance${leaveType.name}');
    expect(
      CommonTest.getTextField('balance${leaveType.name}'),
      contains(usedOfAllowance),
      reason: 'leave balance of ${leaveType.name} should be $usedOfAllowance',
    );
  }
}
