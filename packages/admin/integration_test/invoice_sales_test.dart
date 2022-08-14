import 'package:admin/main.dart';
import 'package:core/api_repository.dart';
import 'package:core/domains/integration_test.dart';
import 'package:core/services/chat_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Invoice sales test''', (tester) async {
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
    await ProductTest.addProducts(tester, products.sublist(0, 3), check: false);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, customers.sublist(0, 2), check: false);
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
