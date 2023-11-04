// ignore_for_file: depend_on_referenced_packages
import 'package:user_company_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  Future<void> selectSuppliers(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbCompanies', 'CompanyListFormSupplier', '4');
  }

  testWidgets('''GrowERP company Supplier test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        UserCompanyLocalizations.localizationsDelegates,
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
