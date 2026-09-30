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

class ClaimTest {
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
                of: find.byKey(const Key('ClaimDialog')),
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

  static Future<void> selectClaims(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/claims', 'ClaimList');
  }

  /// report claims; the policy is searched by the policyNumber of the claim
  static Future<void> addClaims(WidgetTester tester, List<Claim> claims) async {
    for (final claim in claims) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.waitForKey(tester, 'ClaimDialog');
      await CommonTest.enterAutocompleteValue(
        tester,
        'policy',
        claim.policyNumber!,
      );
      await _show(tester, 'incidentDate');
      await CommonTest.enterDate(
        tester,
        'incidentDate',
        claim.incidentDate!,
        usDate: true,
      );
      await _show(tester, 'description');
      await CommonTest.enterText(tester, 'description', claim.description!);
      if (claim.amountClaimed != null) {
        await _show(tester, 'amountClaimed');
        await CommonTest.enterText(
          tester,
          'amountClaimed',
          claim.amountClaimed.toString(),
        );
      }
      await _show(tester, 'update');
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  /// agency staff follow up the claim in row [index] with the carrier
  static Future<void> updateClaim(
    WidgetTester tester,
    int index, {
    ClaimStatus? status,
    String? claimNumber,
    String? amountPaid,
  }) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'ClaimDialog');
    if (claimNumber != null) {
      await _show(tester, 'claimNumber');
      await CommonTest.enterText(tester, 'claimNumber', claimNumber);
    }
    if (status != null) {
      await _show(tester, 'status');
      await CommonTest.selectDropDown(tester, 'status', status.name);
    }
    if (amountPaid != null) {
      await _show(tester, 'amountPaid');
      await CommonTest.enterText(tester, 'amountPaid', amountPaid);
    }
    await _show(tester, 'update');
    await CommonTest.tapByKey(tester, 'update', seconds: 3);
    await CommonTest.waitForKey(tester, 'item$index');
  }

  static Future<void> checkClaim(
    WidgetTester tester,
    int index, {
    ClaimStatus? status,
    String? policyNumber,
  }) async {
    await CommonTest.waitForKey(tester, 'status$index');
    if (status != null) {
      expect(
        CommonTest.getTextField('status$index'),
        status.name,
        reason: 'claim $index should have status ${status.name}',
      );
    }
    if (policyNumber != null) {
      expect(CommonTest.getTextField('policy$index'), policyNumber);
    }
  }
}
