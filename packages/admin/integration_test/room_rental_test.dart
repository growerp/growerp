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

  testWidgets('''GrowERP room rental sales order test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: true);

    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, [categories[0]], check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, [products[2]], check: false);
    await AssetTest.selectAsset(tester);
    await AssetTest.addAssets(tester, [assets[2]], check: false);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, [customers[0]], check: false);
    await OrderTest.selectSalesOrders(tester);
    await OrderTest.createRentalSalesOrder(tester, rentalSalesOrders);
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
