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
