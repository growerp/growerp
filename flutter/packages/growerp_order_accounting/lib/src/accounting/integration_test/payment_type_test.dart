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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

class PaymentTypeTest {
  static Future<void> selectPaymentType(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/accounting/setup',
      'PaymentTypeList',
    );
  }

  static bool showAll(WidgetTester tester) {
    try {
      expect(find.text('All'), findsOneWidget);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteAllPaymentTypes(WidgetTester tester) async {
    if (showAll(tester) == true) {
      // switch to show used only
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    while (tester.any(find.byKey(const Key('delete0')))) {
      await CommonTest.tapByKey(tester, 'delete0', seconds: 2);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<void> addPaymentTypes(
    WidgetTester tester,
    List<PaymentType> paymentTypes, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (showAll(tester) == false) {
      // switch to show all payment types
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    await enterPaymentTypeData(tester, paymentTypes);
    await PersistFunctions.persistTest(
      test.copyWith(paymentTypes: paymentTypes),
    );
    if (check) {
      await PersistFunctions.persistTest(
        test.copyWith(
          paymentTypes: await checkPaymentType(tester, paymentTypes),
        ),
      );
    }
  }

  static Future<void> enterPaymentTypeData(
    WidgetTester tester,
    List<PaymentType> paymentTypes,
  ) async {
    for (PaymentType paymentType in paymentTypes) {
      await CommonTest.enterText(
        tester,
        'searchField',
        "${paymentType.paymentTypeName} -- "
            "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
            "${paymentType.isApplied ? 'Y' : 'N'}",
      );
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
      final ptKey =
          '${paymentType.paymentTypeId}_${paymentType.isPayable ? 1 : 0}_${paymentType.isApplied ? 1 : 0}';
      await CommonTest.enterAutocompleteValue(
        tester,
        'glAccount_$ptKey',
        paymentType.accountCode,
      );
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<PaymentType>> checkPaymentType(
    WidgetTester tester,
    List<PaymentType> paymentTypes,
  ) async {
    List<PaymentType> newPaymentTypes = [];
    for (PaymentType paymentType in paymentTypes) {
      await CommonTest.enterText(
        tester,
        'searchField',
        "${paymentType.paymentTypeName} -- "
            "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
            "${paymentType.isApplied ? 'Y' : 'N'}",
      );
      await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
      expect(
        CommonTest.getTextField('name0'),
        contains(paymentType.paymentTypeName),
      );
      final ptKey =
          '${paymentType.paymentTypeId}_${paymentType.isPayable ? 1 : 0}_${paymentType.isApplied ? 1 : 0}';
      expect(
        CommonTest.getTextFormField('glAccountField_$ptKey'),
        contains(paymentType.accountCode),
      );
      newPaymentTypes.add(paymentType);
    }
    return newPaymentTypes;
  }
}
