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

  testWidgets('''GrowERP Invoice sales test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    // prepare
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      //"categories": categories.sublist(0, 2), created by products
      "products": products.sublist(0, 3),
      "users": customers.sublist(0, 2)
    });
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.addInvoices(tester, salesInvoices.sublist(0, 1));
    await InvoiceTest.updateInvoices(tester, salesInvoices.sublist(1, 2));
    await InvoiceTest.sendOrApproveInvoices(tester);
    await PaymentTest.selectSalesPayments(tester);
    await PaymentTest.sendReceivePayment(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
  });
}
