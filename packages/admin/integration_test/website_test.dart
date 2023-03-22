import 'package:admin/menu_option_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;
import 'package:growerp_website/growerp_website.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbCompany', 'WebsiteForm', '3');
  }

  testWidgets('''GrowERP website test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "categories": categories.sublist(0, 2),
      "products": products.sublist(0, 2),
    });
    await selectWebsite(tester);
    await WebsiteTest.updateWebsite(tester);
  });
}
