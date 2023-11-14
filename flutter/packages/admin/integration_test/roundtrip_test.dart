/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:admin/main.dart';
import 'package:admin/menu_options.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;
import 'package:hive_flutter/hive_flutter.dart';

/// the full business roundtrip for physical products
/// purchase products and receive in warehouse
/// sell the puchase products from the warehouse.
/// full accounting

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets('''GrowERP roundtrip Purchase test''', (tester) async {
    await CommonTest.startTestApp(
      title: "RoundTrip Test",
      clear: false, // use data from previous run, ifnone same as true
      tester,
      router.generateRoute,
      menuOptions,
      extraDelegates,
    );
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "products": products.sublist(0, 2), // will add categories too
      "users": suppliers.sublist(0, 2) + [customers[0]],
    });
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.createPurchaseOrder(tester, purchaseOrders);
    await OrderTest.checkPurchaseOrder(tester);
    await OrderTest.sendPurchaseOrder(tester, purchaseOrders);
    await InventoryTest.selectIncomingShipments(tester);
    await InventoryTest.checkIncomingShipments(tester);
    await InventoryTest.acceptShipmentInInventory(tester);
    await InventoryTest.selectWareHouseLocations(tester);
    await InventoryTest.checkInventoryQOH(tester);
    await InvoiceTest.selectPurchaseInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.checkOrderCompleted(tester);
    await PaymentTest.selectPurchasePayments(tester);
    // confirm purchase payment paid
    await PaymentTest.sendReceivePayment(tester);
    // check purchase payment complete
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.checkPaymentComplete(tester);
    // check purchase invoice complete
    await InvoiceTest.selectPurchaseInvoices(tester);
    await InvoiceTest.checkInvoicesComplete(tester);
    // check purchase orders complete
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.checkPurchaseOrdersComplete(tester);
  }, skip: false);

  testWidgets('''GrowERP roundtrip sales test''', (tester) async {
    // no clear because dependend on purchase test
    await CommonTest.startTestApp(
        tester, router.generateRoute, menuOptions, extraDelegates,
        clear: false); // have to use data from previous testWidget
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.createSalesOrder(tester, salesOrders);
    await OrderTest.checkSalesOrder(tester);
    await OrderTest.approveSalesOrder(tester);
    await InventoryTest.selectOutgoingShipments(tester);
    await InventoryTest.sendOutGoingShipments(tester);
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.checkOrderCompleted(tester);
    await PaymentTest.selectSalesPayments(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
    await PaymentTest.selectSalesPayments(tester);
    // confirm sales payment received
    await PaymentTest.sendReceivePayment(tester);
    // check sales payment complete
    await PaymentTest.checkPaymentComplete(tester);
    // check sales invoice complete
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoicesComplete(tester);
    await CommonTest.logout(tester);
  });
}
