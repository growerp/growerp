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

  Future<void> selectCustomers(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbCompanies', 'CompanyListFormCustomer', '2');
  }

  testWidgets('''GrowERP company customer test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        UserCompanyLocalizations.localizationsDelegates,
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
}
