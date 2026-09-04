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
import 'package:universal_io/io.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

import 'test_file_picker.dart';

class GlAccountTest {
  static Future<void> selectLedger(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/accounting/ledger', 'LedgerTree');
  }

  static Future<void> selectLedgerAccounts(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/accounting/ledger-accounts',
      'GlAccountList',
    );
  }

  static Future<void> addGlAccounts(
    WidgetTester tester,
    List<GlAccount> glAccounts, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.glAccounts.isEmpty) {
      // not yet created
      await enterGlAccountData(tester, glAccounts);
      await PersistFunctions.persistTest(test.copyWith(glAccounts: glAccounts));
    }
    if (check) {
      await PersistFunctions.persistTest(
        test.copyWith(glAccounts: await checkGlAccount(tester, glAccounts)),
      );
    }
  }

  static Future<void> updateGlAccounts(
    WidgetTester tester,
    List<GlAccount> glAccounts,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    var newGlAccounts = List.of(test.glAccounts);
    if (newGlAccounts[0].accountName != glAccounts[0].accountName) {
      // get new glAccounts preserving id
      for (int x = 0; x < test.glAccounts.length; x++) {
        newGlAccounts[x] = glAccounts[x].copyWith(
          glAccountId: test.glAccounts[x].glAccountId,
        );
      }
      await enterGlAccountData(
        tester,
        newGlAccounts,
        searchAccounts: test.glAccounts,
      );
      await PersistFunctions.persistTest(
        test.copyWith(glAccounts: newGlAccounts),
      );
    }
    await checkGlAccount(tester, newGlAccounts);
  }

  static Future<void> deleteLastGlAccount(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'glAccountItem');
    if (count == test.glAccounts.length) {
      await CommonTest.gotoMainMenu(tester);
      await selectLedgerAccounts(tester);
      await CommonTest.tapByKey(
        tester,
        'delete${count - 1}',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.gotoMainMenu(tester);
      await selectLedgerAccounts(tester);
      expect(find.byKey(const Key('glAccountItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(
        test.copyWith(
          glAccounts: test.glAccounts.sublist(0, test.glAccounts.length - 1),
        ),
      );
    }
  }

  /// Download the ledger CSV, put the given balances in it and upload it back
  /// as the initial balance of [periodYear]. [balances] maps an account code
  /// to a signed trial balance amount, debit positive and credit negative.
  static Future<void> initialUpload(
    WidgetTester tester, {
    required String periodYear,
    required Map<String, String> balances,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('glAccountTest');
    final csvPath = '${tempDir.path}/GlAccounts.csv';
    FilePickerPlatform.instance = TestFilePicker(csvPath);

    await CommonTest.tapByKey(tester, 'upDownload');
    await CommonTest.tapByKey(tester, 'download', seconds: CommonTest.waitTime);
    final csvFile = File(csvPath);
    expect(csvFile.existsSync(), true, reason: 'downloaded CSV not saved');

    // put the balances in the last column of the accounts they belong to
    final lines = await csvFile.readAsLines();
    for (int i = 0; i < lines.length; i++) {
      final columns = lines[i].split(',');
      if (columns.length < 6) continue;
      final balance = balances[columns[0].trim()];
      if (balance == null) continue;
      columns[5] = balance;
      lines[i] = columns.join(',');
    }
    await csvFile.writeAsString(lines.join('\n'));

    await CommonTest.enterText(tester, 'periodYear', periodYear);
    await CommonTest.tapByKey(tester, 'upload', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    await tempDir.delete(recursive: true);
  }

  /// Check the posted balance the initial upload created for every account.
  static Future<void> checkPostedBalances(
    WidgetTester tester,
    Map<String, String> balances,
  ) async {
    for (final entry in balances.entries) {
      await CommonTest.doNewSearch(tester, searchString: entry.key);
      expect(find.byKey(const Key('GlAccountDialog')), findsOneWidget);
      expect(
        CommonTest.getTextFormField('postedBalance'),
        equals(entry.value),
        reason: 'posted balance of account ${entry.key}',
      );
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.tapByKey(tester, 'clearSearch');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterGlAccountData(
    WidgetTester tester,
    List<GlAccount> glAccounts, {
    List<GlAccount>? searchAccounts,
  }) async {
    for (int i = 0; i < glAccounts.length; i++) {
      final GlAccount glAccount = glAccounts[i];
      // When updating, search by the OLD accountCode (before the change).
      if (glAccount.glAccountId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: glAccount.glAccountId!,
        );
        expect(
          CommonTest.getTextField('topHeader').split('#')[1].trim(),
          glAccount.glAccountId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'GlAccountDialog');
      await CommonTest.enterText(tester, 'code', glAccount.accountCode!);
      await CommonTest.enterText(tester, 'name', glAccount.accountName!);
      // Select account class via Autocomplete
      await CommonTest.enterAutocompleteValue(
        tester,
        'class',
        glAccount.accountClass!.description!,
      );
      if (glAccount.accountType != null) {
        await CommonTest.enterAutocompleteValue(
          tester,
          'type',
          glAccount.accountType!.description!,
        );
      }
      if (glAccount.postedBalance != null) {
        await CommonTest.enterText(
          tester,
          'postedBalance',
          glAccount.postedBalance.toString(),
        );
      }
      await CommonTest.dragNew(tester);
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<GlAccount>> checkGlAccount(
    WidgetTester tester,
    List<GlAccount> glAccounts,
  ) async {
    List<GlAccount> newGlAccounts = [];
    for (GlAccount glAccount in glAccounts) {
      await CommonTest.doNewSearch(
        tester,
        searchString: glAccount.accountCode!,
      );
      expect(find.byKey(const Key('GlAccountDialog')), findsOneWidget);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      expect(
        CommonTest.getTextFormField('code'),
        equals(glAccount.accountCode!),
      );
      expect(
        CommonTest.getTextFormField('name'),
        equals(glAccount.accountName!),
      );
      if (glAccount.accountType != null) {
        expect(
          CommonTest.getTextFormField('typeField'),
          equals(glAccount.accountType?.description!),
        );
      }
      expect(
        CommonTest.getTextFormField('classField'),
        contains(glAccount.accountClass!.description!),
      );
      newGlAccounts.add(glAccount.copyWith(glAccountId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.tapByKey(tester, 'clearSearch');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    return newGlAccounts;
  }
}
