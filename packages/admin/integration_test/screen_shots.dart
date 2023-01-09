import 'package:admin/menuOption_data.dart';
import 'package:growerp_core/domains/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''Make screenshots''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester, demoData: true);
    await CommonTest.takeScreenshot(tester, binding, 'dashBoard');
    await CompanyTest.selectCompany(tester);
    await CommonTest.takeScreenshot(tester, binding, 'CompayInfo');
  });
}
