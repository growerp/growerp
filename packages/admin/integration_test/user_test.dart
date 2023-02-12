import 'package:admin/menu_option_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:admin/router.dart' as router;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

// this test requires company test to run first

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP user test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await UserTest.selectEmployees(tester);
    await UserTest.addAdministrators(tester, administrators.sublist(0, 3));
    await UserTest.updateAdministrators(tester, administrators.sublist(3, 6));
    await UserTest.deleteAdministrators(tester);
    await UserTest.selectEmployees(tester);
    await UserTest.addEmployees(tester, employees.sublist(0, 3));
    await UserTest.updateEmployees(tester, employees.sublist(3, 6));
    await UserTest.deleteEmployees(tester);
    await UserTest.selectLeads(tester);
    await UserTest.addLeads(tester, leads.sublist(0, 3));
    await UserTest.updateLeads(tester, leads.sublist(3, 6));
    await UserTest.deleteLeads(tester);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, customers.sublist(0, 1));
    await UserTest.updateCustomers(tester, customers.sublist(1, 2));
    await UserTest.deleteCustomers(tester);
    await UserTest.selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2));
    await UserTest.updateSuppliers(tester, suppliers.sublist(2, 4));
    await UserTest.deleteSuppliers(tester);
  });
}
