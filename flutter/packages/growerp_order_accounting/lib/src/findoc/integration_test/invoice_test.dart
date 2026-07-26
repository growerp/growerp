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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

import 'integration_test.dart';

class InvoiceTest {
  static Future<void> selectPurchaseInvoices(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/purchase',
      'PurchaseInvoice',
    );
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> selectSalesInvoices(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(tester, '/accounting/sales', 'SalesInvoice');
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

  static Future<void> checkPdf(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'print0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.byKey(const Key('back')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'back');
  }
}
