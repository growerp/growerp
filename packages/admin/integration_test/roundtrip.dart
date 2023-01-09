import 'package:admin/menuOption_data.dart';
import 'package:growerp_core/domains/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;

/// the full business roundtrip for physical products
/// purchase products and receive in warehouse
/// sell the puchase products from the warehouse.
/// full accounting

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP roundtrip Purchase test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, categories.sublist(0, 2),
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, products.sublist(0, 2), check: false);
    await UserTest.selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2), check: false);
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.createPurchaseOrder(tester, purchaseOrders);
    await OrderTest.checkPurchaseOrder(tester);
    await OrderTest.sendPurchaseOrder(tester, purchaseOrders);
    await WarehouseTest.selectIncomingShipments(tester);
    await WarehouseTest.checkIncomingShipments(tester);
    await WarehouseTest.acceptShipmentInWarehouse(tester);
    await WarehouseTest.selectWareHouseLocations(tester);
    await WarehouseTest.checkWarehouseQOH(tester);
    await InvoiceTest.selectPurchaseInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
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
    await OrderTest.selectPurchaseOrders(tester);
    await OrderTest.checkPurchaseOrdersComplete(tester);
  });

  testWidgets('''GrowERP roundtrip sales test''', (tester) async {
    // no clear because dependend on purchase test
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, [customers[0]], check: false);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.createSalesOrder(tester, salesOrders);
    await OrderTest.checkSalesOrder(tester);
    await OrderTest.approveSalesOrder(tester);
    await WarehouseTest.selectOutgoingShipments(tester);
    await WarehouseTest.sendOutGoingShipments(tester);
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
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
