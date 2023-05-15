// ignore_for_file: depend_on_referenced_packages
import 'package:user_company_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectEmployees(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbPersons', 'UserListFormEmployee', '1');
  }

  Future<void> selectLeads(WidgetTester tester) async {
    await UserTest.selectUsers(tester, 'dbPersons', 'UserListFormLead', '2');
  }

  Future<void> selectCustomers(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbPersons', 'UserListFormCustomer', '3');
  }

  Future<void> selectSuppliers(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbPersons', 'UserListFormSupplier', '4');
  }

  testWidgets('''GrowERP user test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true, title: 'GrowERP user-employee test');
    await CommonTest.createCompanyAndAdmin(tester);
    await selectEmployees(tester);
    await UserTest.addAdministrators(tester, administrators.sublist(0, 3));
    await UserTest.updateAdministrators(tester, administrators.sublist(3, 6));
    await UserTest.deleteAdministrators(tester);
    await selectEmployees(tester);
    await UserTest.addEmployees(tester, employees.sublist(0, 3));
    await UserTest.updateEmployees(tester, employees.sublist(3, 6));
    await UserTest.deleteEmployees(tester);
  }, skip: false);

  testWidgets('''GrowERP lead test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true, title: 'GrowERP user-lead test');
    await CommonTest.createCompanyAndAdmin(tester);
    await selectLeads(tester);
    await UserTest.addLeads(tester, leads.sublist(0, 3));
    await UserTest.updateLeads(tester, leads.sublist(3, 6));
    await UserTest.deleteLeads(tester);
  });

  testWidgets('''GrowERP customer test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true, title: 'GrowERP user-customer test');
    await CommonTest.createCompanyAndAdmin(tester);
    await selectCustomers(tester);
    await UserTest.addCustomers(tester, customers.sublist(0, 1));
    await UserTest.updateCustomers(tester, customers.sublist(1, 2));
    await UserTest.deleteCustomers(tester);
  });

  testWidgets('''GrowERP supplier test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true, title: 'GrowERP user-supplier test');
    await CommonTest.createCompanyAndAdmin(tester);
    await selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2));
    await UserTest.updateSuppliers(tester, suppliers.sublist(2, 4));
    await UserTest.deleteSuppliers(tester);
  });
}
