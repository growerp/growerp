import 'package:workflow/main.dart';
import 'package:workflow/menu_options.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workflow/router.dart' as router;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets('''Make screenshots''', (tester) async {
    await CommonTest.startTestApp(
        tester, router.generateRoute, menuOptions, extraDelegates,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    await binding.takeScreenshot('dashBoard');
    await CompanyTest.selectCompany(tester);
    await CommonTest.takeScreenshot(tester, binding, 'CompanyInfo');
  });
}
