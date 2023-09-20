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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class InvoiceTest {
  static Future<void> selectPurchaseInvoices(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctPurchase', 'FinDocListFormPurchaseInvoice');
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  static Future<void> selectSalesInvoices(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctSales', 'FinDocListFormSalesInvoice');
  }

  static Future<void> addInvoices(WidgetTester tester, List<FinDoc> invoices,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    // test = test.copyWith(invoices: []); //======= remove
    // await PersistFunctions.persistTest(test); //=====remove
    if (test.invoices.isEmpty) {
      await PersistFunctions.persistTest(
          test.copyWith(invoices: await enterInvoiceData(tester, invoices)));
    }
    if (check) {
      test = await PersistFunctions.getTest();
      await checkInvoice(tester, test.invoices);
    }
  }

  static Future<void> updateInvoices(
      WidgetTester tester, List<FinDoc> invoices) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.invoices[0].description != invoices[0].description) {
      // copy invoiceId
      for (int x = 0; x < invoices.length; x++) {
        invoices[x] =
            invoices[x].copyWith(invoiceId: test.invoices[x].invoiceId);
      }
      test = test.copyWith(invoices: await enterInvoiceData(tester, invoices));
      await PersistFunctions.persistTest(test);
    }
    await checkInvoice(tester, test.invoices);
  }

  static Future<void> deleteLastInvoice(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'finDocItem');
    if (count == test.invoices.length) {
      await CommonTest.tapByKey(tester, 'edit${count - 1}');
      await CommonTest.tapByKey(tester, 'cancelFinDoc', seconds: 5);
      // refresh not work in test
      //await CommonTest.refresh(tester);
      //expect(find.byKey(Key('finDocItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          payments: test.invoices.sublist(0, test.invoices.length - 1)));
    }
  }

  static Future<List<FinDoc>> enterInvoiceData(
      WidgetTester tester, List<FinDoc> invoices) async {
    int index = 0;
    List<FinDoc> newInvoices = []; // with invoiceId added
    for (FinDoc invoice in invoices) {
      if (invoice.invoiceId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: invoice.invoiceId!);
        await CommonTest.tapByKey(tester, 'edit0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            invoice.invoiceId);
      }
      await CommonTest.checkWidgetKey(
          tester, "FinDocDialog${invoice.sales ? 'Sales' : 'Purchase'}Invoice");
      // enter supplier/customer
      await CommonTest.enterDropDownSearch(
          tester,
          invoice.sales ? 'customer' : 'supplier',
          invoice.otherUser!.lastName!);
      await CommonTest.enterText(tester, 'description', invoice.description!);
      // delete existing invoice items
      SaveTest test = await PersistFunctions.getTest();
      if (test.invoices.isNotEmpty && test.invoices[index].items.isNotEmpty) {
        await CommonTest.drag(tester, listViewName: 'listView1');
        for (int x = 0; x < test.invoices[index].items.length; x++) {
          await CommonTest.tapByKey(tester, 'delete0');
        }
      }
      // items
      for (FinDocItem item in invoice.items) {
        await CommonTest.tapByKey(tester, 'addProduct', seconds: 1);
        await CommonTest.checkWidgetKey(tester, 'addProductItemDialog');
        await CommonTest.enterDropDownSearch(
            tester, 'product', item.description!);
        await CommonTest.enterText(tester, 'itemPrice', item.price.toString());
        await CommonTest.enterText(
            tester, 'itemQuantity', item.quantity.toString());
        await CommonTest.drag(tester, listViewName: 'listView3');
        await CommonTest.tapByKey(tester, 'ok');
      }
      await CommonTest.drag(tester, seconds: 2);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
      // create new findoc with invoiceId
      FinDoc newFinDoc =
          invoice.copyWith(invoiceId: CommonTest.getTextField('id0'));
      // get productId's
      List<FinDocItem> newItems = [];
      await CommonTest.tapByKey(tester, 'id0'); //open detail
      for (FinDocItem item in invoice.items) {
        FinDocItem newItem = item.copyWith(
            productId: CommonTest.getTextField('itemLine0').split(' ')[1]);
        newItems.add(newItem);
      }
      await CommonTest.tapByKey(tester, 'id0'); // close detail
      newInvoices.add(newFinDoc.copyWith(items: newItems));
      await tester.pumpAndSettle(); // for the message to disappear
      index++;
    }
    await CommonTest.closeSearch(tester);
    return newInvoices;
  }

  static Future<void> checkInvoice(
      WidgetTester tester, List<FinDoc> invoices) async {
    for (FinDoc invoice in invoices) {
      await CommonTest.doSearch(tester, searchString: invoice.invoiceId!);
      expect(CommonTest.getTextField('grandTotal0'),
          equals(invoice.grandTotal.toString()));
      await CommonTest.tapByKey(tester, 'id0'); // open detail
      // items
      for (FinDocItem item in invoice.items) {
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
          find.byKey(
              Key('FinDocDialog${invoice.sales == true ? "Sales" : "Purchase"}'
                  '${invoice.docType}')),
          findsOneWidget);
      expect(
          CommonTest.getDropdownSearch(
              invoice.sales == true ? "customer" : "supplier"),
          contains(invoice.otherUser?.company!.name));
      expect(CommonTest.getTextFormField('description'),
          equals(invoice.description));
      int index = 0;
      for (FinDocItem item in invoice.items) {
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

  static Future<void> checkInvoices(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    expect(orders.isNotEmpty, true,
        reason: 'This test needs orders created in previous steps');
    List<FinDoc> finDocs = [];
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // save invoice Id with order
      String invoiceId = CommonTest.getTextField('id0');
      finDocs.add(order.copyWith(invoiceId: invoiceId));
      // check list
      await CommonTest.tapByKey(tester, 'id0'); // open items
      expect(order.items[0].productId,
          CommonTest.getTextField('itemLine0').split(' ')[1]);
      await CommonTest.tapByKey(tester, 'id0'); // close items
    }
    await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
  }

  static Future<void> sendOrApproveInvoices(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> invoices = test.orders.isNotEmpty
        ? test.orders
        : test.invoices.isNotEmpty
            ? test.invoices
            : test.payments;
    expect(invoices.isNotEmpty, true,
        reason: 'This test needs invoices created in previous steps');
    for (FinDoc invoice in test.invoices) {
      await CommonTest.doSearch(tester, searchString: invoice.invoiceId!);
      if (CommonTest.getTextField('status0') == 'in Preparation') {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 3);
      }
      if (CommonTest.getTextField('status0') == 'Created') {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 3);
      }
      await CommonTest.checkText(tester, 'Approved');
    }
  }

  /// check if the purchase process has been completed successfuly
  static Future<void> checkInvoicesComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> invoices = test.orders.isNotEmpty
        ? test.orders
        : test.invoices.isNotEmpty
            ? test.invoices
            : test.payments;
    for (FinDoc invoice in invoices) {
      await CommonTest.doSearch(tester, searchString: invoice.invoiceId!);
      expect(CommonTest.getTextField('status0'), 'Completed');
    }
  }
}
