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
import 'package:growerp_models/growerp_models.dart';

import 'integration_test.dart';

class PaymentTest {
  static Future<void> selectPurchasePayments(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctPurchase', 'FinDocListPurchasePayment', '2');
  }

  static Future<void> selectSalesPayments(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
        tester, 'acctSales', 'FinDocListSalesPayment', '2');
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
        newPayments[x] = payments[x].copyWith(
            paymentId: test.payments[x].paymentId,
            pseudoId: test.payments[x].paymentId);
      }
      // update existing records, no need to use return data
      await enterPaymentData(tester, newPayments);
      await PersistFunctions.persistTest(test.copyWith(payments: newPayments));
    }
    await checkPayment(tester, newPayments);
  }

  static Future<List<FinDoc>> enterPaymentData(
      WidgetTester tester, List<FinDoc> payments) async {
    List<FinDoc> newPayments = [];
    for (FinDoc payment in payments) {
      if (payment.paymentId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: payment.paymentId!);
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            payment.paymentId,
            reason: 'found different detail than was searched for');
      }
      await CommonTest.checkWidgetKey(
          tester, "PaymentDialog${payment.sales ? 'Sales' : 'Purchase'}");
      await CommonTest.enterDropDownSearch(
          tester, 'otherCompany', payment.otherCompany!.name!);
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
      await CommonTest.enterDropDown(
          tester, 'paymentType', payment.items[0].paymentType!.accountCode);
//      await CommonTest.drag(tester, listViewName: 'listView2', seconds: 2);
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
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
      await CommonTest.doNewSearch(tester,
          searchString: payment.paymentId!, seconds: 5);
      expect(CommonTest.getDropdownSearch('otherCompany'),
          equals(payment.otherCompany!.name));
      expect(CommonTest.getDropdown('statusDropDown'),
          equals(FinDocStatusVal.created.toString()));
      expect(
          find.byKey(Key(
              'PaymentDialog${payment.sales == true ? "Sales" : "Purchase"}')),
          findsOneWidget);
      expect(CommonTest.getTextFormField('amount'),
          equals(payment.grandTotal.currency(currencyId: '')));
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
      await CommonTest.doNewSearch(tester, searchString: payment.id()!);
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

  /// approve payments
  static Future<void> approvePayments(WidgetTester tester) async {
    // default approve
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.payment);
  }

  /// complete/post a payment related to an order
  static Future<void> completePayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.payment,
        status: FinDocStatusVal.completed);
  }

  /// check if a payment related to an order  has the status complete
  static Future<void> checkPaymentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.payment);
    // check if have transactions generated
    List<FinDoc> transactions =
        await FinDocTest.getFinDocs(FinDocType.transaction);
    List<FinDoc> payments = await FinDocTest.getFinDocs(FinDocType.payment);
    expect(payments.length, transactions.length,
        reason: "#transactions(${transactions.length}) should be the same "
            "as #payments(${payments.length}");
  }

  /// cancel a payment
  static Future<void> deleteLastPayment(WidgetTester tester) async {
    await FinDocTest.cancelLastFinDoc(tester, FinDocType.payment);
  }
}
