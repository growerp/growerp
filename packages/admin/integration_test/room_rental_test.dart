import 'package:admin/menu_option_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;
import 'data.dart' as data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP room rental sales order test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, [data.categories[0]],
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, [data.products[2]], check: false);
    await AssetTest.selectAsset(tester);
    await AssetTest.addAssets(tester, [data.assets[2]], check: false);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, [data.customers[0]], check: false);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.createRentalSalesOrder(tester, data.rentalSalesOrders);
    await OrderTest.checkRentalSalesOrder(tester);
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveSalesOrder(tester);
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.checkOrderCompleted(tester);
  });
}
