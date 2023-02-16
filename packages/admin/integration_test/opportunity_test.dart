import 'package:admin/menu_option_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP opportunity test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await UserTest.selectEmployees(tester);
    await UserTest.addAdministrators(tester, administrators.sublist(0, 2),
        check: false);
    await UserTest.selectLeads(tester);
    await UserTest.addLeads(tester, leads.sublist(0, 2), check: false);
    await OpportunityTest.selectOpportunities(tester);
    await OpportunityTest.addOpportunities(tester, opportunities.sublist(0, 4));
    await OpportunityTest.updateOpportunities(
        tester, opportunities.sublist(4, 8));
    await OpportunityTest.deleteLastOpportunity(tester);
  });
}
