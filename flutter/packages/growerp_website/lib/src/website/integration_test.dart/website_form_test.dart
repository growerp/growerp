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

/// Web form CRUD helpers. The pseudoIds the backend allocates are returned by
/// [addWebForms] so the caller can feed them back into the check/update/delete
/// steps; WebsiteForm has no SaveTest slot to persist them between test files.
class WebsiteFormTest {
  static Future<void> selectWebForms(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/webForms', 'WebsiteFormList', null);
  }

  /// Creates every form in [webForms] and returns them with the allocated
  /// pseudoId filled in, in the same order.
  static Future<List<WebsiteForm>> addWebForms(
    WidgetTester tester,
    List<WebsiteForm> webForms,
  ) async {
    List<WebsiteForm> created = [];
    for (WebsiteForm webForm in webForms) {
      await CommonTest.tapByKey(tester, 'addNew');
      expect(find.byKey(const Key('WebsiteFormDialog')), findsOneWidget);
      await enterWebFormData(tester, webForm);
      // the new form is the last row: its pseudoId is on screen now
      await CommonTest.doNewSearch(tester, searchString: webForm.formName);
      final id = CommonTest.getTextFormField('formName') == webForm.formName
          ? _pseudoIdOfOpenDialog(tester)
          : '';
      expect(id.isNotEmpty, true, reason: 'no pseudoId allocated');
      await CommonTest.tapByKey(tester, 'cancel');
      created.add(webForm.copyWith(pseudoId: id));
    }
    await clearSearch(tester);
    return created;
  }

  static Future<void> updateWebForms(
    WidgetTester tester,
    List<WebsiteForm> webForms,
  ) async {
    for (WebsiteForm webForm in webForms) {
      await CommonTest.doNewSearch(tester, searchString: webForm.pseudoId);
      expect(find.byKey(const Key('WebsiteFormDialog')), findsOneWidget);
      await enterWebFormData(tester, webForm);
    }
    await clearSearch(tester);
  }

  static Future<void> checkWebForms(
    WidgetTester tester,
    List<WebsiteForm> webForms,
  ) async {
    for (WebsiteForm webForm in webForms) {
      await CommonTest.doNewSearch(tester, searchString: webForm.pseudoId);
      expect(find.byKey(const Key('WebsiteFormDialog')), findsOneWidget);
      expect(
        CommonTest.getTextFormField('formName'),
        equals(webForm.formName),
      );
      expect(CommonTest.getTextFormField('formTitle'), equals(webForm.title));
      expect(
        CommonTest.getTextFormField('submitLabel'),
        equals(webForm.submitLabel),
      );
      expect(
        CommonTest.getTextFormField('successMessage'),
        equals(webForm.successMessage),
      );
      for (int i = 0; i < webForm.fields.length; i++) {
        expect(
          CommonTest.getTextFormField('fieldLabel$i'),
          equals(webForm.fields[i].label),
        );
        expect(
          CommonTest.getDropdown('fieldType$i'),
          equals(webForm.fields[i].fieldType),
        );
      }
      // an existing form shows the snippet to embed it on a content page
      expect(find.byKey(const Key('embedCode')), findsOneWidget);
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }

  /// Deletes the last form in the list and checks the row count drops by one.
  static Future<void> deleteLastWebForm(
    WidgetTester tester,
    int currentCount,
  ) async {
    expect(
      find.byKey(Key('formName${currentCount - 1}')),
      findsOneWidget,
      reason: 'expected $currentCount web form rows',
    );
    await CommonTest.tapByKey(
      tester,
      'delete${currentCount - 1}',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(tester, 'continue', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    expect(find.byKey(Key('formName${currentCount - 1}')), findsNothing);
  }

  /// Fills the open dialog and saves. Existing field rows are reused; extra
  /// rows are added with 'addField'.
  static Future<void> enterWebFormData(
    WidgetTester tester,
    WebsiteForm webForm,
  ) async {
    await CommonTest.enterText(tester, 'formName', webForm.formName);
    await CommonTest.enterText(tester, 'formTitle', webForm.title);
    await CommonTest.enterText(tester, 'submitLabel', webForm.submitLabel);
    await CommonTest.enterText(
      tester,
      'successMessage',
      webForm.successMessage,
    );

    for (int i = 0; i < webForm.fields.length; i++) {
      if (!tester.any(find.byKey(Key('fieldLabel$i')))) {
        await CommonTest.dragUntil(
          tester,
          key: 'addField',
          listViewName: 'listView',
        );
        await CommonTest.tapByKey(tester, 'addField');
      }
      await CommonTest.enterText(
        tester,
        'fieldLabel$i',
        webForm.fields[i].label,
      );
      await _selectFieldType(tester, i, webForm.fields[i].fieldType);
    }

    await CommonTest.dragUntil(
      tester,
      key: 'update',
      listViewName: 'listView',
    );
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// Clear the search field to show all rows again.
  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Picks a field type by exact label. CommonTest.enterDropDown matches with
  /// `textContaining` and taps the last hit, so asking for 'text' would select
  /// 'textarea'.
  static Future<void> _selectFieldType(
    WidgetTester tester,
    int index,
    String fieldType,
  ) async {
    await CommonTest.dragUntil(
      tester,
      key: 'fieldType$index',
      listViewName: 'listView',
    );
    await tester.tap(find.byKey(Key('fieldType$index')));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    final item = find.text(fieldType);
    expect(
      item.evaluate().isNotEmpty,
      true,
      reason: 'no dropdown item "$fieldType" for fieldType$index',
    );
    await tester.tap(item.last, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// The dialog title reads `Web Form #NNN` once the form exists.
  static String _pseudoIdOfOpenDialog(WidgetTester tester) {
    final title = CommonTest.getTextField('topHeader');
    return title.contains('#') ? title.split('#')[1].trim() : '';
  }
}
