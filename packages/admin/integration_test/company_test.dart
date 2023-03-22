import 'package:admin/menu_option_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;
import 'package:growerp_user_company/growerp_user_company.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectCompany(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbCompany', 'ShowCompanyDialogCompanyForm', '1');
  }

  Future<void> selectCustomers(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'CompanyListFormCustomer', '2');
  }

  Future<void> selectLeads(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbCrm', 'CompanyListFormCompanyLead', '3');
  }

  Future<void> selectSuppliers(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbOrders', 'CompanyListFormSupplier', '4');
  }

  testWidgets('''GrowERP company test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        title: "growerp_user_company: main company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await CommonTest.selectTopCompany(tester);
    await CompanyTest.checkCompany(tester);
    await selectCompany(tester);
    await CompanyTest.checkCompany(tester);
    await CompanyTest.enterCompanyData(tester, [company]); // modify
    await CommonTest.selectTopCompany(tester);
    await CompanyTest.checkCompany(tester);
    await selectCompany(tester);
    await CompanyTest.checkCompany(tester);
  }, skip: false);

  testWidgets('''GrowERP customer test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        title: "growerp_user_company: customer company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await selectCustomers(tester); // create
    await CompanyTest.enterCompanyData(tester, customerCompanies.sublist(0, 2));
    await selectCustomers(tester);
    await CompanyTest.checkCompany(tester);
    await selectCustomers(tester); // update
    await CompanyTest.enterCompanyData(tester, customerCompanies.sublist(2, 4));
    await selectCustomers(tester);
    await CompanyTest.checkCompany(tester);
  }, skip: false);

  testWidgets('''GrowERP lead test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        title: "growerp_user_company: lead company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await selectLeads(tester);
    await CompanyTest.enterCompanyData(tester, leadCompanies.sublist(0, 3));
    await selectLeads(tester);
    await CompanyTest.checkCompany(tester);
    await selectLeads(tester);
    await CompanyTest.enterCompanyData(tester, leadCompanies.sublist(3, 6));
    await selectLeads(tester);
    await CompanyTest.checkCompany(tester);
  }, skip: false);

  testWidgets('''GrowERP Supplier test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        title: "growerp_user_company: Supplier company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await selectSuppliers(tester);
    await CompanyTest.enterCompanyData(tester, supplierCompanies.sublist(0, 2));
    await selectSuppliers(tester);
    await CompanyTest.checkCompany(tester);
    await selectSuppliers(tester);
    await CompanyTest.enterCompanyData(tester, supplierCompanies.sublist(2, 4));
    await selectSuppliers(tester);
    await CompanyTest.checkCompany(tester);
  });
}
