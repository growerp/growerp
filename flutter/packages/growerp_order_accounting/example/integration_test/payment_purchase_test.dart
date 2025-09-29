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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:order_accounting_example/main.dart' as router;
import 'package:order_accounting_example/main.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP payment purchase test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      router.generateRoute,
      testMenuOptions,
      OrderAccountingLocalizations.localizationsDelegates,
      title: 'Payment Purchase Test',
      restClient: restClient,
      blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    ); // use data from previous run, ifnone same as true
    List<Company> companies = [
      company.copyWith(partyId: '_MOD_', name: initialCompany.name),
    ];
    companies.addAll(supplierCompanies.sublist(0, 4));
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"companies": companies},
    );
    await CommonTest.logout(tester); // get updated company payment info
    await CommonTest.login(tester);
    await PaymentTest.selectPurchasePayments(tester);
    await PaymentTest.addPayments(tester, purchasePayments.sublist(0, 4));
    await PaymentTest.updatePayments(tester, purchasePayments.sublist(4, 8));
    await PaymentTest.deleteLastPayment(tester);
    await PaymentTest.approvePayments(tester);
    await PaymentTest.completePayments(tester);
    await PaymentTest.checkPaymentsComplete(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionsComplete(tester);
    await CommonTest.logout(tester);
  });
}
