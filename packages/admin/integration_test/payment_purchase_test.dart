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

  testWidgets('''GrowERP payment purchase test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: true);
    await CompanyTest.createCompany(tester);
    await CompanyTest.selectCompany(tester);
    await CompanyTest.updateAddress(tester, check: false);
    await CompanyTest.updatePaymentMethod(tester, check: false);
    await UserTest.selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2), check: false);
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.addPayments(tester, purchasePayments.sublist(0, 4));
    await PaymentTest.updatePayments(tester, purchasePayments.sublist(4, 8));
    await PaymentTest.deleteLastPayment(tester);
    await PaymentTest.sendReceivePayment(tester);
    await PaymentTest.checkPaymentComplete(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
  });
}
