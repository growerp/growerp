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

class LedgerJournalTest {
  static Future<void> selectLedgerJournal(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctLedger', 'LedgerJournalListFormLedgerJournal', '4');
  }

  static Future<void> addLedgerJournals(
      WidgetTester tester, List<LedgerJournal> ledgerJournals,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    test =
        test.copyWith(ledgerJournals: []); // delete just for test only-------
    if (test.ledgerJournals.isEmpty) {
      // not yet created
      await enterLedgerJournalData(tester, ledgerJournals);
      await PersistFunctions.persistTest(
          test.copyWith(ledgerJournals: ledgerJournals));
    }
    if (check) {
      await PersistFunctions.persistTest(test.copyWith(
          ledgerJournals: await checkLedgerJournal(tester, ledgerJournals)));
    }
  }

  static Future<void> updateLedgerJournals(
      WidgetTester tester, List<LedgerJournal> ledgerJournals) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    var newLedgerJournals = List.of(test.ledgerJournals);
    if (newLedgerJournals[0].journalName != ledgerJournals[0].journalName) {
      // get new ledgerJournals preserving id
      for (int x = 0; x < test.ledgerJournals.length; x++) {
        newLedgerJournals[x] = ledgerJournals[x]
            .copyWith(journalId: test.ledgerJournals[x].journalId);
      }
      await enterLedgerJournalData(tester, newLedgerJournals);
      await PersistFunctions.persistTest(
          test.copyWith(ledgerJournals: newLedgerJournals));
    }
    await checkLedgerJournal(tester, newLedgerJournals);
  }

  static Future<void> deleteLastLedgerJournal(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'ledgerJournalItem');
    if (count == test.ledgerJournals.length) {
      await CommonTest.gotoMainMenu(tester);
      await selectLedgerJournal(tester);
      await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
      await CommonTest.gotoMainMenu(tester);
      await selectLedgerJournal(tester);
      expect(
          find.byKey(const Key('ledgerJournalItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          ledgerJournals:
              test.ledgerJournals.sublist(0, test.ledgerJournals.length - 1)));
    }
  }

  static Future<void> enterLedgerJournalData(
      WidgetTester tester, List<LedgerJournal> ledgerJournals) async {
    for (LedgerJournal ledgerJournal in ledgerJournals) {
      if (ledgerJournal.journalId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester,
            searchString: ledgerJournal.journalId);
        await CommonTest.tapByKey(tester, 'name0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            ledgerJournal.journalId);
      }
      await CommonTest.checkWidgetKey(tester, 'LedgerJournalDialog');
      await CommonTest.enterText(tester, 'name', ledgerJournal.journalName);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<LedgerJournal>> checkLedgerJournal(
      WidgetTester tester, List<LedgerJournal> ledgerJournals) async {
    List<LedgerJournal> newLedgerJournals = [];
    for (LedgerJournal ledgerJournal in ledgerJournals) {
      await CommonTest.doSearch(tester,
          searchString: ledgerJournal.journalName);
      expect(
          CommonTest.getTextField('name0'), equals(ledgerJournal.journalName));
      await CommonTest.tapByKey(tester, 'name0');
      expect(find.byKey(const Key('LedgerJournalDialog')), findsOneWidget);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      expect(CommonTest.getTextFormField('name'),
          equals(ledgerJournal.journalName));
      newLedgerJournals.add(ledgerJournal.copyWith(journalId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newLedgerJournals;
  }
}
