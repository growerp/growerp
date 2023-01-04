import 'package:example/main.dart';
import 'package:core/api_repository.dart';
import 'package:core/domains/integration_test.dart';
import 'package:core/services/chat_server.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_marketing/opportunities/integration_test/data.dart';
import 'package:growerp_marketing/opportunities/integration_test/opportunity_test.dart';
// ignore: depend_on_referenced_packages
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP opportunity test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: false); // use data from previous run, ifnone same as true
/*    await CompanyTest.createCompany(tester);
    await UserTest.selectAdministrators(tester);
    await UserTest.addAdministrators(tester, administrators.sublist(0, 2),
        check: false);
    await UserTest.selectLeads(tester);
    await UserTest.addLeads(tester, leads.sublist(0, 2), check: false);
*/
    await OpportunityTest.selectOpportunities(tester);
//    await OpportunityTest.addOpportunities(tester, opportunities.sublist(0, 4));
    await OpportunityTest.updateOpportunities(
        tester, opportunities.sublist(4, 8));
    await OpportunityTest.deleteLastOpportunity(tester);
  });
}
