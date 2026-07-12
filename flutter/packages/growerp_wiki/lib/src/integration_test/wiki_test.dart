/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

/// Integration test helpers for the wiki page list + editor.
class WikiTest {
  static Future<void> selectWiki(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/wiki', 'WikiList');
  }

  /// Create an authored page, re-open it and confirm the text persisted,
  /// then update it and confirm again.
  static Future<void> addAndUpdatePage(WidgetTester tester) async {
    const pagePath = 'notes/integration-test';
    const text1 = '# Integration Test\n\nfirst version';
    const text2 = '# Integration Test\n\nsecond version';

    // add
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.checkWidgetKey(tester, 'WikiPageDialog');
    await CommonTest.enterText(tester, 'pagePath', pagePath);
    await CommonTest.enterText(tester, 'pageText', text1);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // re-open via search and check content
    await openPage(tester, pagePath);
    expect(
      CommonTest.getTextFormField('pageText'),
      contains('first version'),
    );

    // update
    await CommonTest.enterText(tester, 'pageText', text2);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    await openPage(tester, pagePath);
    expect(
      CommonTest.getTextFormField('pageText'),
      contains('second version'),
    );
    await CommonTest.tapByKey(tester, 'cancel');
  }

  /// Search for [pagePath], tap the first row and switch the dialog to edit
  /// mode so the raw text is accessible.
  static Future<void> openPage(WidgetTester tester, String pagePath) async {
    await CommonTest.enterText(tester, 'searchField', pagePath);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.tapByKey(tester, 'wikiItem0', seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, 'WikiPageDialog');
    // existing pages open in preview mode; toggle to edit for the text field
    await CommonTest.tapByKey(tester, 'editToggle');
  }
}
