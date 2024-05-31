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

class OrderTest {
  static Future<void> selectPurchaseOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'FinDocListPurchaseOrder', '2');
  }

  static Future<void> selectSalesOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'FinDocListSalesOrder', '1');
  }

  static Future<void> createPurchaseOrder(
      WidgetTester tester, List<FinDoc> finDocs) async {
    List<FinDoc> orders = [];
    for (FinDoc order in finDocs) {
      // enter purchase order dialog
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.checkWidgetKey(tester, 'FinDocDialogPurchaseOrder');
      await CommonTest.tapByKey(tester, 'clear', seconds: 2);
      await CommonTest.enterText(tester, 'description', order.description!);
      // enter supplier
      await CommonTest.enterDropDownSearch(
          tester, 'supplier', order.otherUser!.company!.name!);
      // add product data
      await CommonTest.tapByKey(tester, 'addProduct', seconds: 1);
      await CommonTest.checkWidgetKey(tester, 'addProductItemDialog');
      await CommonTest.enterDropDownSearch(
          tester, 'product', order.items[0].description!);
      await CommonTest.drag(tester, listViewName: 'listView3');
      await CommonTest.enterText(
          tester, 'itemPrice', order.items[0].price.toString());
      await CommonTest.enterText(
          tester, 'itemQuantity', order.items[0].quantity.toString());
      await CommonTest.drag(tester);
      await CommonTest.tapByKey(tester, 'ok');
      // create order
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
      // get productId
      await CommonTest.tapByKey(tester, 'id0'); // added at the start
      FinDocItem newItem = order.items[0].copyWith(
          productId: CommonTest.getTextField('itemLine0').split(' ')[1]);
      await CommonTest.tapByKey(tester, 'id0');
      // save order with orderId and productId
      orders.add(order
          .copyWith(orderId: CommonTest.getTextField('id0'), items: [newItem]));
    }
    // save when successfull
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(orders: orders));
  }

  static Future<void> createSalesOrder(
      WidgetTester tester, List<FinDoc> finDocs) async {
    List<FinDoc> orders = [];
    for (FinDoc order in finDocs) {
      // enter order dialog
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.checkWidgetKey(tester, 'FinDocDialogSalesOrder');
      await CommonTest.tapByKey(tester, 'clear', seconds: 2);
      await CommonTest.enterText(tester, 'description', order.description!);
      // enter supplier
      await CommonTest.enterDropDownSearch(
          tester, 'customer', order.otherUser!.company!.name!);
      // add product data
      for (FinDocItem item in order.items) {
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
      // create order
      await CommonTest.drag(tester, listViewName: 'listView1');
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
      // get productId
      await CommonTest.tapByKey(tester, 'id0');
      List<FinDocItem> newItems = List.of(order.items);
      for (int index = 0; index < order.items.length; index++) {
        var productId = CommonTest.getTextField('itemLine$index').split(' ')[1];
        FinDocItem newItem = order.items[index].copyWith(productId: productId);
        newItems[index] = newItem;
      }
      await CommonTest.tapByKey(tester, 'id0');
      // save order with orderId and productId
      orders.add(order.copyWith(
          orderId: CommonTest.getTextField('id0'), items: newItems));
    }
    // save when successfull
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(orders: orders));
  }

  static Future<void> createRentalSalesOrder(
      WidgetTester tester, List<FinDoc> finDocs) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> newOrders = [];
    var usFormat = DateFormat('M/d/yyyy');
    for (FinDoc finDoc in finDocs) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.tapByKey(tester, 'customer');
      await CommonTest.tapByText(tester, finDoc.otherUser!.company!.name!);
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
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
      // get productId added at the top
      await CommonTest.tapByKey(tester, 'id0');
      List<FinDocItem> newItems = List.of(finDoc.items);
      for (int index = 0; index < finDoc.items.length; index++) {
        var productId = CommonTest.getTextField('itemLine$index').split(' ')[1];
        FinDocItem newItem = finDoc.items[index].copyWith(productId: productId);
        newItems[index] = newItem;
      }
      await CommonTest.tapByKey(tester, 'id0'); // close again
      newOrders.add(finDoc.copyWith(
          orderId: CommonTest.getTextField('id0'), items: newItems));
    }
    await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
  }

  static Future<void> checkPurchaseOrder(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // check list
      expect(CommonTest.getTextField('id0'), equals(order.orderId!));
      await CommonTest.tapByKey(tester, 'id0'); // open detail
      expect(order.items[0].productId,
          CommonTest.getTextField('itemLine0').split(' ')[1]);
      await CommonTest.checkText(tester, order.items[0].description!);
      await CommonTest.tapByKey(tester, 'id0'); // close detail
      // check detail
      await CommonTest.tapByKey(tester, 'edit0');
      await CommonTest.checkText(tester, order.orderId!);
      await CommonTest.checkText(tester, order.items[0].description!);
      await CommonTest.tapByKey(tester, 'cancel'); // cancel dialog
      await CommonTest.closeSearch(tester);
    }
  }

  static Future<void> checkSalesOrder(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // check list
      expect(CommonTest.getTextField('id0'), equals(order.orderId!));
      await CommonTest.tapByKey(tester, 'id0'); // open detail
      for (int index = 0; index < order.items.length; index++) {
        expect(order.items[index].productId,
            CommonTest.getTextField('itemLine$index').split(' ')[1]);
        await CommonTest.checkText(tester, order.items[index].description!);
      }
      await CommonTest.tapByKey(tester, 'id0'); // close detail
      // check detail
      await CommonTest.tapByKey(tester, 'edit0');
      await CommonTest.checkText(tester, order.orderId!);
      await CommonTest.checkText(tester, order.items[0].description!);
      await CommonTest.tapByKey(tester, 'cancel'); // cancel dialog
      await CommonTest.closeSearch(tester);
    }
  }

  static Future<void> checkRentalSalesOrder(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var intlFormat = DateFormat('yyyy-MM-dd');
    int x = 0;
    for (FinDoc order in test.orders) {
      expect(CommonTest.getTextField('status$x'), equals('Created'));
      await CommonTest.tapByKey(tester, 'id$x', seconds: 5);
      expect(CommonTest.getTextField('itemLine$x'),
          contains(intlFormat.format(order.items[0].rentalFromDate!)));
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

  static Future<void> sendPurchaseOrder(
      WidgetTester tester, List<FinDoc> orders) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // in the app the order starts as created
      //    await CommonTest.tapByKey(tester, 'nextStatus0',
      //        seconds: 5); // to created
      await CommonTest.tapByKey(tester, 'nextStatus0',
          seconds: 5); // to approved
    }
    await CommonTest.gotoMainMenu(tester);
  }

  static Future<void> approveSalesOrder(WidgetTester tester,
      {String classificationId = 'AppAdmin'}) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
//    starts as 'created' in the app, in the website as inprep
//      await CommonTest.tapByKey(tester, 'nextStatus0',
//          seconds: 5); // to created
      await CommonTest.tapByKey(tester, 'nextStatus0',
          seconds: 5); // to approved
      expect(CommonTest.getTextField('status0'),
          equals(classificationId == 'AppHotel' ? 'Checked In' : 'Approved'));
    }
    await CommonTest.gotoMainMenu(tester);
  }

  static Future<void> checkOrderCompleted(WidgetTester tester,
      {String classificationId = 'AppAdmin'}) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      expect(CommonTest.getTextField('status0'),
          equals(classificationId == 'AppHotel' ? 'Checked Out' : 'Completed'));
    }
  }

  /// check if the purchase order has been completed successfuly
  static Future<void> checkPurchaseOrdersComplete(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    expect(orders.isNotEmpty, true,
        reason: 'This test needs orders created in previous steps');
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      expect(CommonTest.getTextField('status0'), 'Completed');
    }
  }

  static Future<void> addOrders(WidgetTester tester, List<FinDoc> orders,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    // test = test.copyWith(orders: []); //======= remove
    // await PersistFunctions.persistTest(test); //=====remove
    if (test.orders.isEmpty) {
      await PersistFunctions.persistTest(
          test.copyWith(orders: await enterOrderData(tester, orders)));
    }
    if (check) {
      test = await PersistFunctions.getTest();
      await checkOrders(tester, test.orders);
    }
  }

  static Future<void> updateOrders(
      WidgetTester tester, List<FinDoc> orders) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.orders[0].description != orders[0].description) {
      // copy orderId
      for (int x = 0; x < orders.length; x++) {
        orders[x] = orders[x].copyWith(orderId: test.orders[x].orderId);
      }
      test = test.copyWith(orders: await enterOrderData(tester, orders));
      await PersistFunctions.persistTest(test);
    }
    await checkOrders(tester, test.orders);
  }

  static Future<void> deleteLastOrder(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    var count = CommonTest.getWidgetCountByKey(tester, 'finDocItem');
    if (count == test.orders.length) {
      await CommonTest.tapByKey(tester, 'edit${count - 1}');
      await CommonTest.tapByKey(tester, 'cancelFinDoc', seconds: 5);
      // refresh not work in test
      //await CommonTest.refresh(tester);
      //expect(find.byKey(Key('finDocItem')), findsNWidgets(count - 1));
      await PersistFunctions.persistTest(test.copyWith(
          payments: test.orders.sublist(0, test.orders.length - 1)));
    }
  }

  static Future<List<FinDoc>> enterOrderData(
      WidgetTester tester, List<FinDoc> orders) async {
    List<FinDoc> newOrders = []; // with orderId added
    for (final order in orders) {
      if (order.orderId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: order.orderId!);
        await CommonTest.tapByKey(tester, 'edit0');
        expect(
            CommonTest.getTextField('topHeader').split('#')[1], order.orderId);
      }
      await CommonTest.checkWidgetKey(
          tester, "FinDocDialog${order.sales ? 'Sales' : 'Purchase'}Order");
      // enter supplier/customer
      await CommonTest.enterDropDownSearch(
          tester,
          order.sales ? 'customer' : 'supplier',
          order.otherUser!.company!.name!);
      await CommonTest.enterText(tester, 'description', order.description!);
      // delete existing order items
      while (tester.any(find.byKey(const Key("itemDelete0")))) {
        await CommonTest.tapByKey(tester, "itemDelete0", seconds: 2);
      }
      // items
      for (final item in order.items) {
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
      await CommonTest.waitForSnackbarToGo(tester);
      // create new findoc with orderId
      FinDoc newFinDoc =
          order.copyWith(pseudoId: CommonTest.getTextField('id0'));
      // get productId's
      List<FinDocItem> newItems = [];
      await CommonTest.tapByKey(tester, 'id0'); //open detail
      for (final (index, item) in order.items.indexed) {
        FinDocItem newItem = item.copyWith(
            productId: CommonTest.getTextField('itemProductId$index'));
        newItems.add(newItem);
      }
      await CommonTest.tapByKey(tester, 'cancel'); // close detail
      newOrders.add(newFinDoc.copyWith(items: newItems));
      await tester.pumpAndSettle(); // for the message to disappear
    }
    await CommonTest.closeSearch(tester);
    return newOrders;
  }

  static Future<void> checkOrders(
      WidgetTester tester, List<FinDoc> orders) async {
    for (FinDoc order in orders) {
      await CommonTest.doNewSearch(tester, searchString: order.pseudoId!);
      expect(
          CommonTest.getDropdownSearch(
              order.sales == true ? "customer" : "supplier"),
          contains(order.otherUser?.company!.name));
      expect(CommonTest.getTextField('grandTotal'),
          contains(order.grandTotal.toString()));
      // items
      for (final (index, item) in order.items.indexed) {
        expect(CommonTest.getTextField('itemProductId$index'), item.productId);
      }
      for (final (index, item) in order.items.indexed) {
        expect(CommonTest.getTextField('itemDescription$index'),
            equals(item.description));
        expect(CommonTest.getTextField('itemPrice$index'),
            equals(item.price.currency()));
        if (!CommonTest.isPhone())
          expect(CommonTest.getTextField('itemQuantity$index'),
              equals(item.quantity.toString()));
      }
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  static Future<List<FinDoc>> getFinDocs(FinDocType type) async {
    final test = await PersistFunctions.getTest();
    switch (type) {
      case FinDocType.order:
        return test.orders;
      case FinDocType.invoice:
        return test.invoices;
      case FinDocType.payment:
        return test.payments;
      case FinDocType.shipment:
        return test.shipments;
      case FinDocType.transaction:
        return test.transactions;
      default:
        return [];
    }
  }

  static Future<void> saveFinDocs(List<FinDoc> finDocs) async {
    final test = await PersistFunctions.getTest();
    switch (finDocs[0].docType) {
      case FinDocType.order:
        await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
        break;
      case FinDocType.invoice:
        await PersistFunctions.persistTest(test.copyWith(invoices: finDocs));
        break;

      case FinDocType.payment:
        await PersistFunctions.persistTest(test.copyWith(payments: finDocs));
        break;

      case FinDocType.shipment:
        await PersistFunctions.persistTest(test.copyWith(shipments: finDocs));
        break;

      case FinDocType.transaction: // add to existing transactions
        final totalTransactions = List.of(test.transactions);
        totalTransactions.addAll(finDocs);
        await PersistFunctions.persistTest(
            test.copyWith(transactions: totalTransactions));
        break;

      default:
    }
  }

  static Future<void> approveOrders(WidgetTester tester) async {
    await approveFinDocs(tester, FinDocType.order);
  }

  static Future<void> approvePayments(WidgetTester tester) async {
    await approveFinDocs(tester, FinDocType.order, subType: FinDocType.payment);
  }

  static Future<void> approveShipments(WidgetTester tester) async {
    await approveFinDocs(tester, FinDocType.order,
        subType: FinDocType.shipment);
  }

  static Future<void> checkPaymentsComplete(WidgetTester tester) async {
    await checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.payment);
  }

  static Future<void> checkInvoicesComplete(WidgetTester tester) async {
    await checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.invoice);
  }

  static Future<void> checkShipmentsComplete(WidgetTester tester) async {
    await checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.shipment);
  }

  static Future<void> checkTransactionsComplete(WidgetTester tester) async {
    await checkFinDocsComplete(tester, FinDocType.order,
        subType: FinDocType.transaction);
  }

  static Future<void> receiveShipments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.shipmentId!);
      await CommonTest.checkWidgetKey(tester, 'ShipmentReceiveDialogPurchase');
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
      await CommonTest.tapByKey(tester, 'update', seconds: 5);
    }
  }

  /// Approve all findocs for a specific type, however when a sub type
  /// is provided the related findoc is approved.
  /// When approving finDocs related documents are created of which the id's
  /// are stored with the main findoc. Transactions however from alldocuments
  /// are stored together in the transaction list under test.
  static Future<void> approveFinDocs(WidgetTester tester, FinDocType type,
      {FinDocType? subType}) async {
    List<FinDoc> oldFinDocs = await getFinDocs(type);
    List<FinDoc> newFinDocs = List.of(oldFinDocs);

    for (FinDoc finDoc in oldFinDocs) {
      // if provided approve related findoc
      String? id;
      switch (subType) {
        case FinDocType.order:
          id = finDoc.orderId;
        case FinDocType.invoice:
          id = finDoc.invoiceId;
        case FinDocType.payment:
          id = finDoc.paymentId;
        case FinDocType.shipment:
          id = finDoc.shipmentId;
        case FinDocType.transaction:
          id = finDoc.transactionId;
        default:
      }

      await CommonTest.doNewSearch(tester,
          searchString: id != null ? id : finDoc.pseudoId!);
      // open detail
      if (CommonTest.getDropdown('statusDropDown') ==
              FinDocStatusVal.inPreparation.toString() ||
          CommonTest.getDropdown('statusDropDown') ==
              FinDocStatusVal.created.toString()) {
        await CommonTest.tapByKey(tester, 'statusDropDown');
        await CommonTest.tapByText(tester, 'approved');
        await CommonTest.tapByKey(tester, 'update', seconds: 2);
      }
      // get related document numbers
      await CommonTest.doNewSearch(tester,
          searchString: id != null ? id : finDoc.pseudoId!);
      switch (type) {
        case FinDocType.order:
          String? paymentId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.payment);
          String? invoiceId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.invoice);
          String? shipmentId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.shipment);
          newFinDocs.add(finDoc.copyWith(
              paymentId: paymentId,
              invoiceId: invoiceId,
              shipmentId: shipmentId));
          break;
        case FinDocType.payment:
          String? transactionId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.transaction);
          newFinDocs.add(FinDoc(
              docType: FinDocType.transaction,
              transactionId: transactionId,
              paymentId: finDoc.paymentId,
              sales: true));
        case FinDocType.invoice:
          String? transactionId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.transaction);
          newFinDocs.add(FinDoc(
              docType: FinDocType.transaction,
              transactionId: transactionId,
              invoiceId: finDoc.invoiceId,
              sales: true));
        case FinDocType.shipment:
          String? transactionId =
              await CommonTest.getRelatedFindoc(tester, FinDocType.transaction);
          newFinDocs.add(FinDoc(
              docType: FinDocType.transaction,
              shipmentId: finDoc.shipmentId,
              transactionId: transactionId,
              sales: true));
        default:
      }
    }
    await CommonTest.tapByKey(tester, 'cancel');
    await saveFinDocs(newFinDocs);
  }

  /// Approve all findocs for a specific type, however when a sub type
  /// is provided the related findoc is approved.
  /// When approving finDocs related documents are created of which the id's
  /// are stored with the main findoc. Transactions however from alldocuments
  /// are stored together in the transaction list under test.
  static Future<void> checkFinDocsComplete(WidgetTester tester, FinDocType type,
      {FinDocType? subType}) async {
    List<FinDoc> oldFinDocs = await getFinDocs(type);

    for (FinDoc finDoc in oldFinDocs) {
      // if provided approve related findoc
      String? id;
      switch (subType) {
        case FinDocType.order:
          id = finDoc.orderId;
        case FinDocType.invoice:
          id = finDoc.invoiceId;
        case FinDocType.payment:
          id = finDoc.paymentId;
        case FinDocType.shipment:
          id = finDoc.shipmentId;
        case FinDocType.transaction:
          id = finDoc.transactionId;
        default:
      }

      await CommonTest.doNewSearch(tester,
          searchString: id != null ? id : finDoc.pseudoId!);
      // open detail
      expect(CommonTest.getDropdown('statusDropDown'),
          FinDocStatusVal.completed.toString());
      await CommonTest.tapByKey(tester, 'cancel');
    }
    // get related document numbers
  }
}
