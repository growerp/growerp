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

  testWidgets('''GrowERP main company test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        UserCompanyLocalizations.localizationsDelegates,
        title: "growerp_user_company: main company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await CommonTest.selectMainCompany(tester);
    await CompanyTest.checkCompany(tester);
    await CompanyTest.enterCompanyData(tester, [company]); // modify
    await CommonTest.selectMainCompany(tester);
    await CompanyTest.checkCompany(tester);
  });
}
