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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart' as data;
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:example/main.dart' as router;
import 'package:example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Invoice sales test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    // prepare
    await CompanyTest.createCompany(tester);
    await CommonTest.login(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, data.categories.sublist(0, 2),
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, data.products.sublist(0, 3),
        check: false);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, data.customers.sublist(0, 2),
        check: false);
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.addInvoices(tester, data.salesInvoices.sublist(0, 1));
    await InvoiceTest.updateInvoices(tester, data.salesInvoices.sublist(1, 2));
    await InvoiceTest.sendOrApproveInvoices(tester);
    await PaymentTest.selectSalesPayments(tester);
    await PaymentTest.sendReceivePayment(tester);
    await PaymentTest.checkPayments(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionComplete(tester);
  });
}