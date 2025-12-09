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
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

import 'integration_test.dart';

class InvoiceTest {
  static Future<void> selectPurchaseInvoices(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(
      tester,
      'accounting/purchase',
      'PurchaseInvoice',
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> selectSalesInvoices(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(tester, 'accounting/sales', 'SalesInvoice');
  }

  static Future<void> addInvoices(
    WidgetTester tester,
    List<FinDoc> invoices,
  ) async {
    await FinDocTest.enterFinDocData(tester, invoices);
    await FinDocTest.checkFinDocDetail(tester, FinDocType.invoice);
  }

  static Future<void> updateInvoices(
    WidgetTester tester,
    List<FinDoc> newFinDocs,
  ) async {
    await FinDocTest.updateFinDocData(tester, newFinDocs);
  }

  static Future<void> deleteLastInvoice(WidgetTester tester) async {
    await FinDocTest.cancelLastFinDoc(tester, FinDocType.invoice);
  }

  static Future<void> checkInvoices(WidgetTester tester) async {
    await FinDocTest.checkFinDocDetail(tester, FinDocType.invoice);
  }

  static Future<void> sendOrApproveInvoices(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.invoice);
  }

  static Future<void> approveInvoicePayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.invoice,
      subType: FinDocType.payment,
    );
  }

  static Future<void> completeInvoicePayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.invoice,
      subType: FinDocType.payment,
      status: FinDocStatusVal.completed,
    );
  }

  static Future<void> checkInvoicePaymentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(
      tester,
      FinDocType.invoice,
      subType: FinDocType.payment,
    );
  }

  /// check if the purchase process has been completed successfuly
  static Future<void> checkInvoicesComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.invoice);
  }
}
