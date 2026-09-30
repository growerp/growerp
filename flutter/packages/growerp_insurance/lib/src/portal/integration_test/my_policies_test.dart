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

  /// the digital card of the policy at [index] shows the plate and a QR
  /// code; with [requestRenewal] the client asks for the renewal
  static Future<void> checkPolicyCard(
    WidgetTester tester,
    int index, {
    String? plate,
    bool requestRenewal = false,
  }) async {
    await CommonTest.tapByKey(tester, 'myPolicyCard$index');
    await CommonTest.waitForKey(tester, 'PolicyCardDialog');
    if (plate != null) {
      expect(CommonTest.getTextField('cardPlate'), equals(plate));
    }
    expect(find.byKey(const Key('cardQr')), findsOneWidget);
    if (requestRenewal) {
      await CommonTest.tapByKey(tester, 'requestRenewal');
      await CommonTest.waitForKey(tester, 'renewalRequested');
    }
    await CommonTest.tapByKey(tester, 'cancel');
  }

  /// report a claim with the guided wizard on the policy whose dropdown
  /// label contains [policyLabel]
  static Future<void> reportClaim(
    WidgetTester tester, {
    required String policyLabel,
    required DateTime incidentDate,
    required String description,
    String location = '',
  }) async {
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.waitForKey(tester, 'ClaimWizardDialog');
    await CommonTest.selectDropDown(tester, 'wizardPolicy', policyLabel);
    await CommonTest.tapByKey(tester, 'incidentType0');
    await CommonTest.tapByKey(tester, 'wizardNext');
    await CommonTest.enterDate(
      tester,
      'incidentDate',
      incidentDate,
      usDate: true,
    );
    await CommonTest.enterText(tester, 'incidentLocation', location);
    await CommonTest.enterText(tester, 'description', description);
    // photos are optional; picking one needs a native picker, so the photo
    // upload is tested through the REST client (see insurance_test)
    await CommonTest.tapByKey(tester, 'wizardNext');
    await CommonTest.tapByKey(tester, 'wizardNext');
    expect(CommonTest.getTextField('photoCount'), contains('0'));
    await CommonTest.tapByKey(tester, 'consent');
    await CommonTest.tapByKey(
      tester,
      'wizardSubmit',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// ask the assistant a question and wait for an answer
  static Future<void> askAssistant(WidgetTester tester, String question) async {
    await CommonTest.tapByKey(tester, 'askAssistant');
    await CommonTest.waitForKey(tester, 'InsuranceAssistantDialog');
    await CommonTest.enterText(tester, 'assistantQuestion', question);
    await CommonTest.tapByKey(
      tester,
      'assistantSend',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForKey(tester, 'assistantMessage1');
    await CommonTest.tapByKey(tester, 'cancel');
  }
}
