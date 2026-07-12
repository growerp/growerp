// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_sales_example/router_builder.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/src/opportunities/integration_test/opportunity_test.dart';
import 'package:growerp_sales/src/opportunities/integration_test/data.dart';
import 'package:growerp_sales/src/opportunities/integration_test/marketing_test_model.dart';
import 'package:growerp_sales/src/opportunities/integration_test/persist_marketing_test.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP opportunity pipeline test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createSalesExampleRouter(),
      salesMenuConfig,
      SalesLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getSalesBlocProviders(restClient),
      clear: true,
      title: "Pipeline test",
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"users": administrators.sublist(0, 2) + leads.sublist(0, 2)},
    );
    // fresh company each run: reset persisted marketing test state so
    // opportunities get created again
    await PersistMarketingTest.save(MarketingTest());
    // create two opportunities in the first two stages via the list view
    await CommonTest.selectOption(tester, '/crm', 'OpportunityList');
    // data: index 0 = Prospecting, index 1 = Qualification
    await OpportunityTest.addOpportunities(
      tester,
      opportunities.sublist(0, 2),
      check: false,
    );
    // open the pipeline board
    await CommonTest.selectOption(tester, '/pipeline', 'OpportunityPipeline');
    expect(find.byKey(const Key('salesFunnelChart')), findsOneWidget);
    expect(find.byKey(const Key('pipelineColumnProspecting')), findsOneWidget);
    expect(
      find.byKey(const Key('pipelineColumnQualification')),
      findsOneWidget,
    );
    // one card in each of the first two columns
    expect(find.byKey(const Key('pipelineItemProspecting0')), findsOneWidget);
    expect(
      find.byKey(const Key('pipelineItemQualification0')),
      findsOneWidget,
    );
    // change stage via the dialog: Prospecting -> Qualification
    await CommonTest.tapByKey(tester, 'pipelineItemProspecting0');
    await CommonTest.checkWidgetKey(tester, 'OpportunityDialog');
    await CommonTest.enterDropDown(tester, 'stageId', 'Qualification');
    await CommonTest.tapByKey(tester, 'update');
    await CommonTest.waitForSnackbarToGo(tester);
    // card moved: Prospecting empty, Qualification has two cards
    expect(find.byKey(const Key('pipelineItemProspecting0')), findsNothing);
    expect(
      find.byKey(const Key('pipelineItemQualification1')),
      findsOneWidget,
    );
    // leave persisted marketing test state clean for other test files
    await PersistMarketingTest.save(MarketingTest());
    await CommonTest.logout(tester);
  });
}
