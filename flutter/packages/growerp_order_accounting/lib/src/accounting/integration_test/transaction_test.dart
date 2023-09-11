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

class TransactionTest {
  static Future<void> selectTransactions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctLedger', 'FinDocListFormTransaction', '3');
  }

  static Future<void> checkTransactionComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> finDocs = test.orders.isNotEmpty
        ? test.orders
        : test.transactions.isNotEmpty
            ? test.transactions
            : test.payments;
    for (FinDoc finDoc in finDocs) {
      await CommonTest.doSearch(tester, searchString: finDoc.chainId()!);
      await tester.pumpAndSettle();
      expect(CommonTest.getTextField('status0'), 'Completed',
          reason: 'transaction status field check');
    }
  }

  static Future<void> addTransactions(
      WidgetTester tester, List<FinDoc> transactions,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    // test = test.copyWith(transactions: []); //======= remove
    // await PersistFunctions.persistTest(test); //=====remove
    if (test.transactions.isEmpty) {
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
      // copy transactionId
      for (int x = 0; x < transactions.length; x++) {
        transactions[x] = transactions[x]
            .copyWith(transactionId: test.transactions[x].transactionId);
      }
      test = test.copyWith(
          transactions: await enterTransactionData(tester, transactions));
      await PersistFunctions.persistTest(test);
    }
    await checkTransaction(tester, test.transactions);
  }

/*
  static Future<void> deleteLastTransaction(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'finDocItem');
    if (count == test.transactions.length) {
      await CommonTest.tapByKey(tester, 'edit${count - 1}');
      await CommonTest.tapByKey(tester, 'cancelFinDoc', seconds: 5);
      // refresh not work in test
      //await CommonTest.refresh(tester);
      //expect(find.byKey(Key('finDocItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          payments:
              test.transactions.sublist(0, test.transactions.length - 1)));
    }
  }
*/
  static Future<List<FinDoc>> enterTransactionData(
      WidgetTester tester, List<FinDoc> transactions) async {
    int index = 0;
    List<FinDoc> newTransactions = []; // with transactionId added
    for (FinDoc transaction in transactions) {
      if (transaction.transactionId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester,
            searchString: transaction.transactionId!);
        await CommonTest.tapByKey(tester, 'edit0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            transaction.transactionId);
      }
      await CommonTest.checkWidgetKey(tester,
          "FinDocDialog${transaction.sales ? 'Sales' : 'Purchase'}Transaction");
      // enter supplier/customer
      await CommonTest.enterDropDownSearch(
          tester,
          transaction.sales ? 'customer' : 'supplier',
          transaction.otherUser!.lastName!);
      await CommonTest.enterText(
          tester, 'description', transaction.description!);
      // delete existing transaction items
      SaveTest test = await PersistFunctions.getTest();
      if (test.transactions.isNotEmpty &&
          test.transactions[index].items.isNotEmpty) {
        await CommonTest.drag(tester, listViewName: 'listView1');
        for (int x = 0; x < test.transactions[index].items.length; x++) {
          await CommonTest.tapByKey(tester, 'delete0');
        }
      }
      // items
      for (FinDocItem item in transaction.items) {
        await CommonTest.tapByKey(tester, 'addProduct', seconds: 1);
        await CommonTest.checkWidgetKey(tester, 'addProductItemDialog');
        await CommonTest.enterDropDownSearch(
            tester, 'product', item.description!);
        await CommonTest.drag(tester, listViewName: 'listView3');
        await CommonTest.enterText(tester, 'itemPrice', item.price.toString());
        await CommonTest.enterText(
            tester, 'itemQuantity', item.quantity.toString());
        await CommonTest.tapByKey(tester, 'ok');
      }
      await CommonTest.drag(tester, seconds: 2);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
      // create new findoc with transactionId
      FinDoc newFinDoc =
          transaction.copyWith(transactionId: CommonTest.getTextField('id0'));
      // get productId's
      List<FinDocItem> newItems = [];
      await CommonTest.tapByKey(tester, 'id0'); //open detail
      for (FinDocItem item in transaction.items) {
        FinDocItem newItem = item.copyWith(
            productId: CommonTest.getTextField('itemLine0').split(' ')[1]);
        newItems.add(newItem);
      }
      await CommonTest.tapByKey(tester, 'id0'); // close detail
      newTransactions.add(newFinDoc.copyWith(items: newItems));
      await tester.pumpAndSettle(); // for the message to disappear
      index++;
    }
    await CommonTest.closeSearch(tester);
    return newTransactions;
  }

  static Future<void> checkTransaction(
      WidgetTester tester, List<FinDoc> transactions) async {
    for (FinDoc transaction in transactions) {
      await CommonTest.doSearch(tester,
          searchString: transaction.transactionId!);
      expect(CommonTest.getTextField('grandTotal0'),
          equals(transaction.grandTotal.toString()));
      await CommonTest.tapByKey(tester, 'id0'); // open detail
      // items
      for (FinDocItem item in transaction.items) {
        expect(
          CommonTest.getTextField('itemLine0').split(' ')[1],
          item.productId,
        );
        await CommonTest.checkText(tester, item.description!);
      }
      await CommonTest.tapByKey(tester, 'id0');
      // detail dialog
      await CommonTest.tapByKey(tester, 'edit0');
      expect(
          find.byKey(Key(
              'FinDocDialog${transaction.sales == true ? "Sales" : "Purchase"}'
              '${transaction.docType}')),
          findsOneWidget);
      expect(
          CommonTest.getDropdownSearch(
              transaction.sales == true ? "customer" : "supplier"),
          contains(transaction.otherUser?.company!.name));
      expect(CommonTest.getTextFormField('description'),
          equals(transaction.description));
      int index = 0;
      for (FinDocItem item in transaction.items) {
        expect(CommonTest.getTextField('itemDescription$index'),
            equals(item.description));
        expect(CommonTest.getTextField('itemPrice$index'),
            equals(item.price.toString()));
//        expect(CommonTest.getTextField('itemQuantity$index'),
//          equals(item.quantity.toString()));
        index++;
      }
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
  }

  static Future<void> checkTransactions(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    expect(orders.isNotEmpty, true,
        reason: 'This test needs orders created in previous steps');
    List<FinDoc> finDocs = [];
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // save transaction Id with order
      String transactionId = CommonTest.getTextField('id0');
      finDocs.add(order.copyWith(transactionId: transactionId));
      // check list
      await CommonTest.tapByKey(tester, 'id0'); // open items
      expect(order.items[0].productId,
          CommonTest.getTextField('itemLine0').split(' ')[1]);
      await CommonTest.tapByKey(tester, 'id0'); // close items
    }
    await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
  }

  static Future<void> postTransactions(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> transactions = test.orders.isNotEmpty
        ? test.orders
        : test.transactions.isNotEmpty
            ? test.transactions
            : test.payments;
    expect(transactions.isNotEmpty, true,
        reason: 'This test needs transactions created in previous steps');
    for (FinDoc transaction in test.transactions) {
      await CommonTest.doSearch(tester,
          searchString: transaction.transactionId!);
      if (CommonTest.getTextField('status0') ==
          finDocStatusValues[FinDocStatusVal.inPreparation.toString()]) {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 5);
      }
      if (CommonTest.getTextField('status0') ==
          finDocStatusValues[FinDocStatusVal.created.toString()]) {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 5);
      }
      await CommonTest.checkText(tester, 'Approved');
    }
  }

  /// check if the purchase process has been completed successfuly
  static Future<void> checkTransactionsComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> transactions = test.orders.isNotEmpty
        ? test.orders
        : test.transactions.isNotEmpty
            ? test.transactions
            : test.payments;
    for (FinDoc transaction in transactions) {
      await CommonTest.doSearch(tester,
          searchString: transaction.transactionId!);
      expect(CommonTest.getTextField('status0'), 'Completed');
    }
  }
}
