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

class GlAccountTest {
  static Future<void> selectLedger(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(tester, 'acctLedger', 'LedgerTree');
  }

  static Future<void> selectLedgerAccounts(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(tester, 'acctLedger', 'GlAccountList', '2');
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
      await enterGlAccountData(tester, newGlAccounts);
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

  static Future<void> enterGlAccountData(
    WidgetTester tester,
    List<GlAccount> glAccounts,
  ) async {
    for (GlAccount glAccount in glAccounts) {
      if (glAccount.glAccountId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: glAccount.glAccountId!);
        await CommonTest.tapByKey(tester, 'code0');
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          glAccount.glAccountId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'GlAccountDialog');
      await CommonTest.enterText(tester, 'code', glAccount.accountCode!);
      await CommonTest.enterText(tester, 'name', glAccount.accountName!);
      await CommonTest.enterDropDownSearch(
        tester,
        'class',
        glAccount.accountClass!.description!,
      );
      if (glAccount.accountType != null) {
        await CommonTest.enterDropDownSearch(
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
      await CommonTest.doSearch(tester, searchString: glAccount.accountCode!);
      expect(CommonTest.getTextField('code0'), equals(glAccount.accountCode));
      expect(CommonTest.getTextField('name0'), equals(glAccount.accountName));
      if (!CommonTest.isPhone()) {
        expect(
          CommonTest.getTextField('class0'),
          equals(glAccount.accountClass!.description),
        );
        if (glAccount.accountType != null) {
          expect(
            CommonTest.getTextField('type0'),
            equals(glAccount.accountType?.description!),
          );
        }
      }
      await CommonTest.tapByKey(tester, 'name0');
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
          CommonTest.getDropdownSearch('type'),
          equals(glAccount.accountType?.description!),
        );
      }
      expect(
        CommonTest.getDropdownSearch('class'),
        contains(glAccount.accountClass!.description!),
      );
      newGlAccounts.add(glAccount.copyWith(glAccountId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newGlAccounts;
  }
}
