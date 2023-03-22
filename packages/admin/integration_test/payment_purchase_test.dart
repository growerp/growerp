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

  testWidgets('''GrowERP payment purchase test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "companies": [
        company.copyWith(partyId: '_MOD_', name: initialCompany.name)
      ],
      "users": suppliers.sublist(0, 2),
    });
    // get above updated company
    await CommonTest.logout(tester);
    await CommonTest.login(tester);
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
