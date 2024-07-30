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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:growerp_models/growerp_models.dart';
import 'integration_test.dart';

class OrderTest {
  static Future<void> selectPurchaseOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'FinDocListPurchaseOrder', '2');
  }

  static Future<void> selectSalesOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'FinDocListSalesOrder', '1');
  }

  static Future<void> selectInventory(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbInventory', 'LocationList');
  }

  static Future<void> addOrders(
    WidgetTester tester,
    List<FinDoc> orders,
  ) async {
    await FinDocTest.enterFinDocData(tester, orders);
    await FinDocTest.checkFinDocDetail(tester, FinDocType.order);
  }

  static Future<void> updateOrders(
      WidgetTester tester, List<FinDoc> newFinDocs) async {
    await FinDocTest.updateFinDocData(tester, newFinDocs);
  }

  static Future<void> deleteLastOrder(WidgetTester tester) async {
    await FinDocTest.cancelLastFinDoc(tester, FinDocType.order);
  }

  static Future<void> checkOrders(WidgetTester tester) async {
    await FinDocTest.checkFinDocDetail(tester, FinDocType.order);
  }

  static Future<void> sendOrApproveOrders(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order);
  }

  static Future<void> approveOrderPayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order,
        subType: FinDocType.payment);
  }

  static Future<void> completeOrderPayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order,
        subType: FinDocType.payment, status: FinDocStatusVal.completed);
  }

  static Future<void> checkOrderPaymentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.payment);
  }

  static Future<void> checkOrderInvoicesComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.invoice);
  }

  static Future<void> createRentalSalesOrder(
      WidgetTester tester, List<FinDoc> finDocs) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> newOrders = [];
    var usFormat = DateFormat('M/d/yyyy');
    for (FinDoc finDoc in finDocs) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.tapByKey(tester, 'customer');
      await CommonTest.tapByText(tester, finDoc.otherCompany!.name!);
      await CommonTest.enterText(tester, 'description', finDoc.description!);
      await CommonTest.tapByKey(tester, 'itemRental');
      await CommonTest.tapByKey(tester, 'product', seconds: 5);
      await CommonTest.tapByText(tester, finDoc.items[0].description!);
      await CommonTest.tapByKey(tester, 'setDate');
      await CommonTest.tapByTooltip(tester, 'Switch to input');
      await tester.enterText(find.byType(TextField).last,
          usFormat.format(finDoc.items[0].rentalFromDate!));
      await tester.pump();
      await CommonTest.tapByText(tester, 'OK');
      DateTime textField = DateTime.parse(CommonTest.getTextField('date'));
      expect(usFormat.format(textField),
          usFormat.format(finDoc.items[0].rentalFromDate!));
      await CommonTest.enterText(
          tester, 'quantity', finDoc.items[0].quantity.toString());
      await CommonTest.drag(tester, listViewName: 'listView4');
      await CommonTest.tapByKey(tester, 'okRental');
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      // tap orderId added at the top to get detail
      await CommonTest.tapByKey(tester, 'id0');
      // get all productId's
      List<FinDocItem> newItems = [];
      for (final (index, item) in finDoc.items.indexed) {
        FinDocItem newItem = item.copyWith(
            product: Product(
                productId: CommonTest.getTextField('itemProductId$index')));
        newItems.add(newItem);
      }
      await CommonTest.tapByKey(tester, 'cancel'); // close again
      newOrders.add(finDoc.copyWith(
          orderId: CommonTest.getTextField('id0'),
          pseudoId: CommonTest.getTextField('id0'),
          items: newItems));
    }
    await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
  }

  static Future<void> checkOrderDetail(tester) async {
    await FinDocTest.checkFinDocDetail(tester, FinDocType.order);
  }

  static Future<void> checkRentalSalesOrder(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    //  var intlFormat = DateFormat('yyyy-MM-dd');
    int x = 0;
    for (FinDoc order in test.orders) {
      expect(
          CommonTest.getTextField('status$x'), equals(FinDocStatusVal.created));
      await CommonTest.tapByKey(tester, 'id$x', seconds: 5);
      expect(CommonTest.getTextField('itemProductId$x'),
          equals(order.items[0].product?.productId));
      x++;
    }
  }

  static Future<void> checkRentalSalesOrderBlocDates(
      WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var usFormat = DateFormat('M/d/yyyy');
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.tapByKey(tester, 'itemRental');
    await CommonTest.tapByKey(tester, 'product');
    await CommonTest.tapByText(tester, test.orders[0].items[0].description!);
    await CommonTest.tapByKey(tester, 'setDate');
    await CommonTest.tapByTooltip(tester, 'Switch to input');
    await tester.enterText(find.byType(TextField).last,
        usFormat.format(test.orders[0].items[0].rentalFromDate!));
    await tester.pump();
    await CommonTest.tapByText(tester, 'OK');
    expect(find.text('Out of range.'), findsOneWidget);
    await CommonTest.tapByText(tester, 'CANCEL');
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> approveSalesOrder(WidgetTester tester,
      {String classificationId = 'AppAdmin'}) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doNewSearch(tester, searchString: order.orderId!);
//    starts as 'created' in the app, in the website as inprep
//      await CommonTest.tapByKey(tester, 'nextStatus0',
//          seconds: 5); // to created
      await CommonTest.tapByKey(tester, 'nextStatus0',
          seconds: 5); // to approved
      expect(
          CommonTest.getTextField('status0'), equals(FinDocStatusVal.approved));
    }
    await CommonTest.gotoMainMenu(tester);
  }

  static Future<void> checkOrderCompleted(WidgetTester tester,
      {String classificationId = 'AppAdmin'}) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doNewSearch(tester, searchString: order.orderId!);
      expect(CommonTest.getTextField('status0'),
          equals(FinDocStatusVal.completed));
    }
  }

  /// approve orders
  static Future<void> approveOrders(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order);
  }

  /// complete orders
  static Future<void> completeOrders(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order,
        status: FinDocStatusVal.completed);
  }

  /// approve shipments related to an order
  static Future<void> approveOrderShipments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order,
        subType: FinDocType.shipment);
  }

  /// complete shipments related to an order
  static Future<void> completeOrderShipments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(tester, FinDocType.order,
        subType: FinDocType.shipment, status: FinDocStatusVal.completed);
  }

  /// check shipments related to an order if complete
  static Future<void> checkOrderShipmentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.shipment);
  }

  /// check if an order has the status complete
  static Future<void> checkOrdersComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.order);
  }
}
