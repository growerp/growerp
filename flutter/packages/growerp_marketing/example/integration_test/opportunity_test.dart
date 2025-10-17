// ignore_for_file: depend_on_referenced_packages
import 'package:marketing_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_marketing/src/opportunities/integration_test/data.dart';
import 'package:growerp_marketing/src/opportunities/integration_test/opportunity_test.dart';

// Static menuOptions for testing (no localization needed)
List<MenuOption> testMenuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const MainMenuForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Marketing',
    route: '/crm',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const OpportunityList(),
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP opportunity test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      MarketingLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getMarketingBlocProviders(restClient),
      clear: true,
      title: "Opportunity test",
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"users": administrators.sublist(0, 2) + leads.sublist(0, 2)},
    );
    await OpportunityTest.selectOpportunities(tester);
    await OpportunityTest.addOpportunities(tester, opportunities.sublist(0, 4));
    await OpportunityTest.updateOpportunities(
      tester,
      opportunities.sublist(4, 8),
    );
    await OpportunityTest.deleteOpportunities(tester);
    await CommonTest.logout(tester);
  });
}
