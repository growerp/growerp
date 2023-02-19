// ignore_for_file: depend_on_referenced_packages
import 'package:example_for_growerp_user_company/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectLeads(WidgetTester tester) async {
    await UserTest.selectUsers(tester, 'dbOtherUsers', 'UserListFormLead', '1');
  }

  Future<void> selectCustomers(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbOtherUsers', 'UserListFormCustomer', '2');
  }

  Future<void> selectSuppliers(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbOtherUsers', 'UserListFormSupplier', '3');
  }

  testWidgets('''GrowERP user test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true, title: 'GrowERP user test');
    await CompanyTest.createCompany(tester);
    await UserTest.selectEmployees(tester);
    await UserTest.addAdministrators(tester, administrators.sublist(0, 3));
    await UserTest.updateAdministrators(tester, administrators.sublist(3, 6));
    await UserTest.deleteAdministrators(tester);
    await UserTest.selectEmployees(tester);
    await UserTest.addEmployees(tester, employees.sublist(0, 3));
    await UserTest.updateEmployees(tester, employees.sublist(3, 6));
    await UserTest.deleteEmployees(tester);
    await selectLeads(tester);
    await UserTest.addLeads(tester, leads.sublist(0, 3));
    await UserTest.updateLeads(tester, leads.sublist(3, 6));
    await UserTest.deleteLeads(tester);
    await selectCustomers(tester);
    await UserTest.addCustomers(tester, customers.sublist(0, 1));
    await UserTest.updateCustomers(tester, customers.sublist(1, 2));
    await UserTest.deleteCustomers(tester);
    await selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2));
    await UserTest.updateSuppliers(tester, suppliers.sublist(2, 4));
    await UserTest.deleteSuppliers(tester);
  });
}
