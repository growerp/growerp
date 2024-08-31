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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

class PaymentTypeTest {
  static Future<void> selectPaymentType(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(tester, 'acctSetup', 'PaymentTypeList', '3');
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
      WidgetTester tester, List<PaymentType> paymentTypes,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (showAll(tester) == false) {
      // switch to show all payment types
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    await enterPaymentTypeData(tester, paymentTypes);
    await PersistFunctions.persistTest(
        test.copyWith(paymentTypes: paymentTypes));
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          paymentTypes: await checkPaymentType(tester, paymentTypes)));
    }
  }

  static Future<void> enterPaymentTypeData(
      WidgetTester tester, List<PaymentType> paymentTypes) async {
    for (PaymentType paymentType in paymentTypes) {
      await CommonTest.doSearch(tester,
          searchString: "${paymentType.paymentTypeName} -- "
              "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
              "${paymentType.isApplied ? 'Y' : 'N'}");
      await CommonTest.enterDropDownSearch(
          tester, 'glAccount0', paymentType.accountCode);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<PaymentType>> checkPaymentType(
      WidgetTester tester, List<PaymentType> paymentTypes) async {
    List<PaymentType> newPaymentTypes = [];
    for (PaymentType paymentType in paymentTypes) {
      await CommonTest.doSearch(tester,
          searchString: "${paymentType.paymentTypeName} -- "
              "${paymentType.isPayable ? 'Outgoing' : 'Incoming'} -- "
              "${paymentType.isApplied ? 'Y' : 'N'}");
      expect(CommonTest.getTextField('name0'),
          contains(paymentType.paymentTypeName));
      expect(CommonTest.getDropdownSearch('glAccount0'),
          contains(paymentType.accountCode));
      newPaymentTypes.add(paymentType);
    }
    return newPaymentTypes;
  }
}
