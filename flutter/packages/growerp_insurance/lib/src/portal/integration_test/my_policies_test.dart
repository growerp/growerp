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

class MyPoliciesTest {
  static Future<void> selectMyPolicies(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/myPolicies', 'MyPoliciesView');
  }

  /// the policy card at [index] shows [policyNumber]
  static Future<void> checkMyPolicy(
    WidgetTester tester,
    int index,
    String policyNumber,
  ) async {
    await CommonTest.waitForKey(tester, 'myPolicy$index');
    expect(
      CommonTest.getTextField('myPolicyTitle$index'),
      contains(policyNumber),
    );
  }

  static Future<void> checkNoOtherPolicies(
    WidgetTester tester,
    int count,
  ) async {
    expect(find.byKey(Key('myPolicy$count')), findsNothing);
  }
}
