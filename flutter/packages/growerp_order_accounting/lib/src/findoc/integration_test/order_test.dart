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
      tester,
      'dbOrders',
      'FinDocListPurchaseOrder',
      '2',
    );
  }

  static Future<void> selectSalesOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      'dbOrders',
      'FinDocListSalesOrder',
      '1',
    );
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
    WidgetTester tester,
    List<FinDoc> newFinDocs,
  ) async {
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
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      subType: FinDocType.payment,
    );
  }

  static Future<void> completeOrderPayments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      subType: FinDocType.payment,
      status: FinDocStatusVal.completed,
    );
  }

  static Future<void> checkOrderPaymentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(
      tester,
      FinDocType.order,
      subType: FinDocType.payment,
    );
  }

  static Future<void> checkOrderInvoicesComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(
      tester,
      FinDocType.order,
      subType: FinDocType.invoice,
    );
  }

  static Future<void> createRentalSalesOrder(
    WidgetTester tester,
    List<FinDoc> finDocs,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> newOrders = [];
    var stdFormat = DateFormat('yyyy-MM-dd');
    for (FinDoc finDoc in finDocs) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.tapByKey(tester, 'customer');
      await CommonTest.tapByText(tester, finDoc.otherCompany!.name!);
      await CommonTest.enterText(tester, 'description', finDoc.description!);
      await CommonTest.tapByKey(tester, 'itemRental');
      await CommonTest.tapByKey(
        tester,
        'product',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.tapByText(tester, finDoc.items[0].description!);
      await CommonTest.tapByKey(tester, 'setDate');
      await CommonTest.tapByTooltip(tester, 'Switch to input');
      await tester.enterText(
        find.byType(TextField).last,
        stdFormat.format(finDoc.items[0].rentalFromDate!),
      );
      await tester.pump();
      await CommonTest.tapByText(tester, 'OK');
      expect(
        CommonTest.getDateTimeFormField('setDate').dateOnly(),
        finDoc.items[0].rentalFromDate.dateOnly(),
      );
      // nbr of days
      await CommonTest.enterText(
        tester,
        'quantity',
        finDoc.items[0].quantity.toString(),
      );
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
      // tap orderId added at the top to get detail
      await CommonTest.tapByKey(tester, 'id0');
      // get all productId's
      List<FinDocItem> newItems = [];
      for (final (index, item) in finDoc.items.indexed) {
        FinDocItem newItem = item.copyWith(
          product: Product(
            pseudoId: CommonTest.getTextField('itemProductId$index'),
          ),
        );
        newItems.add(newItem);
      }
      await CommonTest.tapByKey(tester, 'cancel'); // close again
      newOrders.add(
        finDoc.copyWith(
          orderId: CommonTest.getTextField('id0'),
          pseudoId: CommonTest.getTextField('id0'),
          items: newItems,
        ),
      );
    }
    await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
  }

  static Future<void> checkRentalOrderDetail(WidgetTester tester) async {
    await FinDocTest.checkFinDocDetail(tester, FinDocType.order, rental: true);
  }

  static Future<void> checkRentalSalesOrderBlocDates(
    WidgetTester tester,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    var stdFormat = DateFormat('yyyy-MM-dd');
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.tapByKey(tester, 'itemRental');
    await CommonTest.tapByKey(tester, 'product');
    await CommonTest.tapByText(tester, test.orders[0].items[0].description!);
    await CommonTest.tapByKey(tester, 'setDate');
    await CommonTest.tapByTooltip(tester, 'Switch to input');
    await tester.enterText(
      find.byType(TextField).last,
      stdFormat.format(test.orders[0].items[0].rentalFromDate!),
    );
    await tester.pump();
    await CommonTest.tapByText(tester, 'OK');
    expect(find.text('Out of range.'), findsOneWidget);
    await CommonTest.tapByText(tester, 'CANCEL');
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> checkOrderCompleted(
    WidgetTester tester, {
    String classificationId = 'AppAdmin',
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doNewSearch(tester, searchString: order.orderId!);
      expect(
        CommonTest.getDropdown(
          'statusDropDown',
          classificationId: classificationId,
        ),
        equals(FinDocStatusVal.completed.hotel),
      );
    }
  }

  /// approve orders
  static Future<void> approveOrders(
    WidgetTester tester, {
    String classificationId = 'AppAdmin',
  }) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      classificationId: classificationId,
    );
  }

  /// complete orders
  static Future<void> completeOrders(
    WidgetTester tester, {
    String classificationId = 'AppAdmin',
  }) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      classificationId: classificationId,
      status: FinDocStatusVal.completed,
    );
  }

  /// approve shipments related to an order
  static Future<void> approveOrderShipments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      subType: FinDocType.shipment,
    );
  }

  /// complete shipments related to an order
  static Future<void> completeOrderShipments(WidgetTester tester) async {
    await FinDocTest.changeStatusFinDocs(
      tester,
      FinDocType.order,
      subType: FinDocType.shipment,
      status: FinDocStatusVal.completed,
    );
  }

  /// check shipments related to an order if complete
  static Future<void> checkOrderShipmentsComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(
      tester,
      FinDocType.order,
      subType: FinDocType.shipment,
    );
  }

  /// check if an order has the status complete
  static Future<void> checkOrdersComplete(WidgetTester tester) async {
    await FinDocTest.checkFinDocsComplete(tester, FinDocType.order);
  }
}
