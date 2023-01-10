// ignore: depend_on_referenced_packages
import 'package:growerp_core/domains/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart';
import 'package:growerp_website/growerp_website.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbWebsite', 'WebsiteFormWebsite');
  }

  testWidgets('''GrowERP website test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, categories.sublist(0, 2),
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, products.sublist(0, 2), check: false);

    await selectWebsite(tester);
    await WebsiteTest.updateWebsite(tester);
  });
}
