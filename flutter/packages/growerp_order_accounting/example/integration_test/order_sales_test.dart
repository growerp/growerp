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
import 'package:growerp_inventory/growerp_inventory.dart';
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

  testWidgets('''GrowERP Order sales test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
        tester,
        router.generateRoute,
        menuOptions,
        const [
          OrderAccountingLocalizations.delegate,
          InventoryLocalizations.delegate
        ],
        blocProviders: router.getOrderAccountingBlocProvidersExample(
            restClient, 'AppAdmin'),
        title: "Order Sales test",
        restClient: restClient,
        clear: true); // use data from previous run, ifnone same as true
    // prepare
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "companies": customerCompanies,
      "users": customers,
      "assets": assets, // create locations and products too
    });
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
