import 'package:admin/menu_option_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Invoice Purchase test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true

    await CommonTest.createCompanyAndAdmin(tester, testData: {
      // "categories": categories.sublist(0, 2), will be created by products
      "products": products.sublist(0, 2),
      "users": suppliers.sublist(0, 2),
    });

    // purchase
    await InvoiceTest.selectPurchaseInvoices(tester);
    await InvoiceTest.addInvoices(tester, purchaseInvoices.sublist(0, 3));
    await InvoiceTest.updateInvoices(tester, purchaseInvoices.sublist(3, 5));
    await InvoiceTest.deleteLastInvoice(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.sendReceivePayment(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
  });
}
