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

class PolicyTest {
  /// scroll a field of the dialog into view: the dialog is a lazy list, so a
  /// field below the fold may not be built yet, or built but not hit testable
  static Future<void> _show(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    if (!tester.any(finder)) {
      await tester.scrollUntilVisible(
        finder,
        100,
        // the list of the dialog, not the one of the screen below it nor the
        // horizontal scroller of a text field in it
        scrollable: find
            .descendant(
              of: find.descendant(
                of: find.byKey(const Key('PolicyDialog')),
                matching: find.byKey(const Key('listView')),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  static Future<void> selectPolicies(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/policies', 'PolicyList');
  }

  static Future<void> selectCommissions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/commissions', 'CommissionList');
  }

  /// add policies; insuredName and carrierName are searched in the
  /// customers and suppliers
  static Future<void> addPolicies(
    WidgetTester tester,
    List<Policy> policies,
  ) async {
    for (final policy in policies) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.waitForKey(tester, 'PolicyDialog');
      await CommonTest.enterText(
        tester,
        'policyNumber',
        policy.policyNumber ?? '',
      );
      await CommonTest.enterAutocompleteValue(
        tester,
        'insured',
        policy.insuredName!,
      );
      await CommonTest.enterAutocompleteValue(
        tester,
        'carrier',
        policy.carrierName!,
      );
      await _show(tester, 'policyType');
      await CommonTest.selectDropDown(
        tester,
        'policyType',
        (policy.policyType ?? PolicyType.other).name,
      );
      await _show(tester, 'effectiveDate');
      await CommonTest.enterDate(
        tester,
        'effectiveDate',
        policy.effectiveDate!,
        usDate: true,
      );
      await _show(tester, 'expirationDate');
      await CommonTest.enterDate(
        tester,
        'expirationDate',
        policy.expirationDate!,
        usDate: true,
      );
      if (policy.premiumAmount != null) {
        await _show(tester, 'premium');
        await CommonTest.enterText(
          tester,
          'premium',
          policy.premiumAmount.toString(),
        );
      }
      if (policy.premiumFrequency != null) {
        await _show(tester, 'premiumFrequency');
        await CommonTest.selectDropDown(
          tester,
          'premiumFrequency',
          policy.premiumFrequency!.name,
        );
      }
      if (policy.commissionRate != null) {
        await _show(tester, 'commissionRate');
        await CommonTest.enterText(
          tester,
          'commissionRate',
          policy.commissionRate.toString(),
        );
      }
      final coverages = policy.coverages ?? <PolicyCoverage>[];
      for (int i = 0; i < coverages.length; i++) {
        await _show(tester, 'addCoverage');
        await CommonTest.tapByKey(tester, 'addCoverage');
        await _show(tester, 'coverageName$i');
        await CommonTest.enterText(
          tester,
          'coverageName$i',
          coverages[i].coverageName!,
        );
        if (coverages[i].limitAmount != null) {
          await CommonTest.enterText(
            tester,
            'coverageLimit$i',
            coverages[i].limitAmount.toString(),
          );
        }
      }
      await _show(tester, 'update');
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  static Future<void> checkPolicy(
    WidgetTester tester,
    int index, {
    String? policyNumber,
    PolicyStatus? status,
    String? insuredName,
  }) async {
    await CommonTest.waitForKey(tester, 'item$index');
    if (policyNumber != null) {
      expect(CommonTest.getTextField('policyNumber$index'), policyNumber);
    }
    if (status != null) {
      expect(
        CommonTest.getTextField('status$index'),
        status.name,
        reason: 'policy $index should have status ${status.name}',
      );
    }
    if (insuredName != null) {
      expect(CommonTest.getTextField('insured$index'), contains(insuredName));
    }
  }

  /// renew the policy in row [index]; the list is fetched again, so in the
  /// renewal list the renewed policy disappears
  static Future<void> renewPolicy(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'PolicyDialog');
    await _show(tester, 'renew');
    await CommonTest.tapByKey(tester, 'renew');
    await CommonTest.tapByKey(tester, 'continue', seconds: 3);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('PolicyDialog')), findsNothing);
  }

  static Future<void> receiveCommission(
    WidgetTester tester,
    int index,
    String amount,
  ) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'ReceiveCommissionDialog');
    await CommonTest.enterText(tester, 'amount', amount);
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    await CommonTest.waitForKey(tester, 'item$index');
  }

  static Future<void> checkCommission(
    WidgetTester tester,
    int index, {
    String? expected,
    String? received,
  }) async {
    await CommonTest.waitForKey(tester, 'commissionReceived$index');
    if (expected != null) {
      expect(CommonTest.getTextField('commissionExpected$index'), expected);
    }
    if (received != null) {
      expect(CommonTest.getTextField('commissionReceived$index'), received);
    }
  }
}
