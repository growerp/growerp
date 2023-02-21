// ignore_for_file: depend_on_referenced_packages
import 'package:example/main.dart';
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

  testWidgets('''GrowERP company test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true);

    /// [createCompany]
    await CompanyTest.createCompany(tester);
    await CompanyTest.selectCompany(tester);
    await CompanyTest.updateCompany(tester);

    /// [createCompany]
    await CompanyTest.updateAddress(tester);
    await CompanyTest.updatePaymentMethod(tester);
  });
}
