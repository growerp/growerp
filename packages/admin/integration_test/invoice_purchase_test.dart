import 'package:admin/main.dart';
import 'package:growerp_core/api_repository.dart';
import 'package:growerp_core/domains/integration_test.dart';
import 'package:growerp_core/services/chat_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Invoice Purchase test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: true);
    // prepare
    await CompanyTest.createCompany(tester);
    await CommonTest.login(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, categories.sublist(0, 2),
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, products.sublist(0, 2), check: false);
    await UserTest.selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2), check: false);
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
