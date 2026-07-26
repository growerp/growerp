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
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/shipment_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/payment_test.dart';
import 'package:growerp_order_accounting/src/accounting/integration_test/transaction_test.dart';
import 'package:growerp_inventory/src/integration_test/inventory_test.dart';
import 'package:order_accounting_example/router_builder.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP Order sales test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOrderAccountingExampleRouter(),
      orderAccountingMenuConfig,
      const [
        OrderAccountingLocalizations.delegate,
        InventoryLocalizations.delegate,
      ],
      blocProviders: getOrderAccountingBlocProvidersExample(
        restClient,
        'AppAdmin',
      ),
      title: "Order Sales test",
      restClient: restClient,
      clear: true,
    );
    // prepare
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        "companies": customerCompanies,
        "users": customers,
        "assets": assets, // create locations and products too
      },
    );
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.addOrders(tester, salesOrders.sublist(0, 1));
    await OrderTest.updateOrders(tester, salesOrders.sublist(1, 2));
    await OrderTest.deleteLastOrder(tester);
    await OrderTest.approveOrders(tester);
    await ShipmentTest.selectOutgoingShipments(tester);
    await OrderTest.approveOrderShipments(tester);
    await OrderTest.completeOrderShipments(tester);
    await OrderTest.checkOrderShipmentsComplete(tester);
    await PaymentTest.selectSalesPayments(tester);
    await OrderTest.approveOrderPayments(tester);
    await OrderTest.completeOrderPayments(tester);
    await OrderTest.checkOrderPaymentsComplete(tester);
    await CommonTest.gotoMainMenu(tester);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.checkOrdersComplete(tester);
    await OrderTest.selectInventory(tester);
    await InventoryTest.checkInventory(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.checkTransactionsComplete(tester);
    await CommonTest.logout(tester);
  });
}
