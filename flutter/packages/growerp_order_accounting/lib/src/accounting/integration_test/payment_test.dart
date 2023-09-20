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

class PaymentTest {
  static Future<void> selectPurchasePayments(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctPurchase', 'FinDocListFormPurchasePayment', '2');
  }

  static Future<void> selectSalesPayments(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctSales', 'FinDocListFormSalesPayment', '2');
  }

  static Future<void> addPayments(WidgetTester tester, List<FinDoc> payments,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    // test = test.copyWith(payments: []); //======= remove
    // await PersistFunctions.persistTest(test); //=====remove
    if (test.payments.isEmpty) {
      // not yet created
      await PersistFunctions.persistTest(
          test.copyWith(payments: await enterPaymentData(tester, payments)));
    }
    if (check) {
      await checkPayment(tester, test.payments);
    }
  }

  static Future<void> updatePayments(
      WidgetTester tester, List<FinDoc> payments) async {
    SaveTest test = await PersistFunctions.getTest();
    var newPayments = List.of(test.payments);
    if (newPayments[0].grandTotal != payments[0].grandTotal) {
      // copy new payment data with paymentId
      for (int x = 0; x < test.payments.length; x++) {
        newPayments[x] =
            payments[x].copyWith(paymentId: test.payments[x].paymentId);
      }
      // update existing records, no need to use return data
      await enterPaymentData(tester, newPayments);
      await PersistFunctions.persistTest(test.copyWith(payments: newPayments));
    }
    await checkPayment(tester, newPayments);
  }

  static Future<void> deleteLastPayment(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'finDocItem');
    if (count == test.payments.length) {
      await CommonTest.refresh(tester); // does not work
      await CommonTest.tapByKey(tester, 'edit${count - 1}');
      await CommonTest.tapByKey(tester, 'cancelFinDoc', seconds: 5);
      expect(CommonTest.getTextField('status${count - 1}'),
          equals(finDocStatusValues[FinDocStatusVal.cancelled.toString()]));
      //  only within testing deleted item will not be removed after refresh
      //    await CommonTest.refresh(tester);
      expect(find.byKey(const Key('finDocItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          payments: test.payments.sublist(0, test.payments.length - 1)));
    }
  }

  static Future<List<FinDoc>> enterPaymentData(
      WidgetTester tester, List<FinDoc> payments) async {
    List<FinDoc> newPayments = [];
    for (FinDoc payment in payments) {
      if (payment.paymentId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: payment.paymentId!);
        await CommonTest.tapByKey(tester, 'edit0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            payment.paymentId,
            reason: 'found different detail than was searched for');
      }
      await CommonTest.checkWidgetKey(
          tester, "PaymentDialog${payment.sales ? 'Sales' : 'Purchase'}");
      await CommonTest.enterDropDownSearch(
          tester,
          payment.sales ? 'customer' : 'supplier',
          payment.otherUser!.lastName!);
      await CommonTest.enterText(tester, 'amount',
          payment.grandTotal!.toString()); // required because keyboard come up
      await CommonTest.drag(tester, listViewName: 'listView2');
      switch (payment.paymentInstrument) {
        case PaymentInstrument.bank:
          await CommonTest.tapByKey(tester, 'bank');
          break;
        case PaymentInstrument.creditcard:
          await CommonTest.tapByKey(tester, 'creditCard');
          break;
        case PaymentInstrument.check:
          await CommonTest.tapByKey(tester, 'check');
          break;
        case PaymentInstrument.cash:
          await CommonTest.tapByKey(tester, 'cash');
          break;
        default:
      }
      await CommonTest.enterDropDown(tester, 'itemType',
          '${payment.items[0].itemType!.itemTypeName}\n ${payment.items[0].itemType!.accountName}');
      await CommonTest.drag(tester, listViewName: 'listView2', seconds: 2);
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      await CommonTest.waitForKey(tester, 'dismiss');
      await CommonTest.waitForSnackbarToGo(tester);
      newPayments
          .add(payment.copyWith(paymentId: CommonTest.getTextField('id0')));
    }
    await CommonTest.closeSearch(tester);
    return newPayments;
  }

  static Future<void> checkPayment(
      WidgetTester tester, List<FinDoc> payments) async {
    for (FinDoc payment in payments) {
      await CommonTest.doSearch(tester,
          searchString: payment.paymentId!, seconds: 5);
      expect(CommonTest.getTextField('otherUser0'),
          contains(payment.otherUser?.company!.name));
      expect(CommonTest.getTextField('status0'), equals('Created'));
      expect(CommonTest.getTextField('grandTotal0'),
          equals(payment.grandTotal.toString()));
      await CommonTest.tapByKey(tester, 'edit0');
      expect(
          find.byKey(Key(
              'PaymentDialog${payment.sales == true ? "Sales" : "Purchase"}')),
          findsOneWidget);
      expect(CommonTest.getTextFormField('amount'),
          equals(payment.grandTotal!.toString()));
      switch (payment.paymentInstrument) {
        case PaymentInstrument.creditcard:
          expect(CommonTest.getCheckbox('creditCard'), equals(true));
          break;
        case PaymentInstrument.bank:
          expect(CommonTest.getCheckbox('bank'), equals(true));
          break;
        case PaymentInstrument.cash:
          expect(CommonTest.getCheckbox('cash'), equals(true));
          break;
        case PaymentInstrument.check:
          expect(CommonTest.getCheckbox('check'), equals(true));
          break;
        default:
      }
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
  }

  // not used locally...need replacement
  static Future<void> checkPayments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> payments = test.orders.isNotEmpty
        ? test.orders
        : test.invoices.isNotEmpty
            ? test.invoices
            : test.payments;
    List<FinDoc> finDocs = [];
    for (FinDoc payment in payments) {
      await CommonTest.doSearch(tester, searchString: payment.id()!);
      // payment Id with order
      String paymentId = CommonTest.getTextField('id0');
      // if same as order number , wrong record, get next one
      if (CommonTest.getTextField('id0') == payment.id()) {
        paymentId = CommonTest.getTextField('id0');
      }
      finDocs.add(payment.copyWith(paymentId: paymentId));
      // check list
    }
    switch (payments[0].docType) {
      case FinDocType.order:
        await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
        break;
      case FinDocType.invoice:
        await PersistFunctions.persistTest(test.copyWith(invoices: finDocs));
        break;
      case FinDocType.payment:
        await PersistFunctions.persistTest(test.copyWith(payments: finDocs));
        break;
      default:
    }
  }

  /// assume we are in the purchase payment list
  /// confirm that a payment has been send
  static Future<void> sendReceivePayment(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> payments = test.orders.isNotEmpty
        ? test.orders
        : test.invoices.isNotEmpty
            ? test.invoices
            : test.payments;
    for (FinDoc payment in payments) {
      await CommonTest.doSearch(tester, searchString: payment.id()!);
      if (CommonTest.getTextField('status0') == 'in Preparation') {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 3);
      }
      if (CommonTest.getTextField('status0') == 'Created') {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 3);
      }
      if (CommonTest.getTextField('status0') == 'Approved') {
        await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 3);
      }
    }
    await CommonTest.closeSearch(tester);
  }

  /// check if the purchase process has been completed successfuly
  static Future<void> checkPaymentComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> payments = test.orders.isEmpty ? test.payments : test.orders;
    for (FinDoc payment in payments) {
      await CommonTest.doSearch(tester, searchString: payment.paymentId!);
      expect(CommonTest.getTextField('status0'), 'Completed');
    }
  }
}
