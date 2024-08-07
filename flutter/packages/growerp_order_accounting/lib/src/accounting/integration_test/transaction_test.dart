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

class TransactionTest {
  static Future<void> selectTransactions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctLedger', 'FinDocListTransaction', '3');
  }

  static Future<void> addTransactions(
      WidgetTester tester, List<FinDoc> transactions,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.transactions.isEmpty) {
      // not tested yet
      await PersistFunctions.persistTest(test.copyWith(
          transactions: await enterTransactionData(tester, transactions)));
    }
    if (check) {
      test = await PersistFunctions.getTest();
      await checkTransaction(tester, test.transactions);
    }
  }

  static Future<void> updateTransactions(
      WidgetTester tester, List<FinDoc> transactions) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.transactions[0].description != transactions[0].description) {
      // copy pseudoId
      for (int x = 0; x < transactions.length; x++) {
        transactions[x] =
            transactions[x].copyWith(pseudoId: test.transactions[x].pseudoId);
      }
      test = test.copyWith(
          transactions: await enterTransactionData(tester, transactions));
      await PersistFunctions.persistTest(test);
    }
    await checkTransaction(tester, test.transactions);
  }

  static Future<List<FinDoc>> enterTransactionData(
      WidgetTester tester, List<FinDoc> transactions) async {
    List<FinDoc> newTransactions = []; // with pseudoId added
    for (final transaction in transactions) {
      if (transaction.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester,
            searchString: transaction.pseudoId!);
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            transaction.pseudoId);
      }
      await CommonTest.checkWidgetKey(tester, "FinDocDialogSalesTransaction");
      await CommonTest.enterText(
          tester, 'description', transaction.description!);
      // delete existing transaction items
      while (tester.any(find.byKey(const Key("itemDelete0")))) {
        await CommonTest.tapByKey(tester, "itemDelete0", seconds: 2);
      }
      // items
      for (FinDocItem item in transaction.items) {
        await CommonTest.tapByKey(tester, 'addItem', seconds: 1);
        await CommonTest.checkWidgetKey(tester, 'addTransactionItemDialog');
        await CommonTest.enterDropDownSearch(
            tester, 'glAccount', item.glAccount!.accountCode!);
        await CommonTest.tapByKey(tester, item.isDebit! ? 'debit' : 'credit',
            seconds: 2);
        await CommonTest.enterText(tester, 'price', item.price.toString());
        await CommonTest.tapByKey(tester, 'ok');
      }
      await CommonTest.drag(tester, seconds: 2);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
      // save transactionid if required
      newTransactions.add(transaction.copyWith(
          pseudoId: transaction.pseudoId ?? CommonTest.getTextField('id0')));
    }
    return newTransactions;
  }

  static Future<void> checkTransaction(
      WidgetTester tester, List<FinDoc> transactions) async {
    for (FinDoc transaction in transactions) {
      await CommonTest.doNewSearch(tester, searchString: transaction.pseudoId!);
      expect(CommonTest.getTextField('grandTotal'),
          contains(transaction.grandTotal.currency()));
      expect(
          transaction.description, CommonTest.getTextFormField('description'));
      expect(transaction.isPosted, CommonTest.getRadio('isPosted'),
          reason:
              "should be ${transaction.isPosted! ? 'posted' : 'not posted'} but is not?");
      for (final (index, item) in transaction.items.indexed) {
        expect(item.glAccount!.accountCode!,
            CommonTest.getTextField('accountCode$index'));
        expect(
            item.price.currency(),
            CommonTest.getTextField(
                "${item.isDebit! ? 'debit' : 'credit'}$index"));
      }
      await CommonTest.tapByKey(tester, 'cancel'); // close detail
      await tester.pumpAndSettle(); // for the message to disappear
    }
  }

  static Future<void> postTransactions(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (FinDoc transaction in test.transactions) {
      await CommonTest.doNewSearch(tester, searchString: transaction.pseudoId!);
      await CommonTest.tapByKey(tester, 'isPosted');
      await CommonTest.tapByKey(tester, 'header');
      await CommonTest.tapByKey(tester, 'update');
    }
  }

  static Future<void> checkTransactionsComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (FinDoc transaction in test.transactions) {
      await CommonTest.doNewSearch(tester, searchString: transaction.pseudoId!);
      expect(CommonTest.getRadio('isPosted'), true,
          reason: "posted field should be true now");
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }
}
