/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/payment_test.dart';
import 'package:order_accounting_example/router_builder.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    // Force English locale for tests to ensure consistent date picker behavior
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('''GrowERP order rental test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOrderAccountingExampleRouter(),
      orderAccountingMenuConfig,
      OrderAccountingLocalizations.localizationsDelegates,
      title: "Order rental test",
      restClient: restClient,
      blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    ); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        "assets": assets, // will create product and category too
        "companies": customerCompanies,
      },
    );
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
    await CommonTest.logout(tester);
  });
}
