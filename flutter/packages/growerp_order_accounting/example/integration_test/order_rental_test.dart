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

  testWidgets('''GrowERP order rental test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        OrderAccountingLocalizations.localizationsDelegates,
        title: "Order rental test",
        restClient: restClient,
        blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "assets": assets, // will create product and category too
      "companies": customerCompanies,
    });
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.createRentalSalesOrder(tester, rentalSalesOrders);
    await OrderTest.checkRentalOrderDetail(tester);
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveOrders(tester);
    await PaymentTest.selectSalesPayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);
    await OrderTest.checkOrderPaymentsComplete(tester);
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.completeOrders(tester);
    await OrderTest.checkOrdersComplete(tester);
  });
}
