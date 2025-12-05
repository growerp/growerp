import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_outreach_example/main.dart' as app;
import 'package:growerp_core/growerp_core.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_marketing/growerp_marketing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Platform Configuration test', (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      app.generateRoute,
      app.menuOptions,
      const [UserCompanyLocalizations.delegate],
      restClient: restClient,
      blocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        BlocProvider<PlatformConfigBloc>(
          create: (context) => PlatformConfigBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'Platform Configuration test',
      clear: true,
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Navigate to Platform Configuration
    await CommonTest.selectOption(
        tester, 'Platforms', 'PlatformConfigListScreen');

    // Create new configuration
    await CommonTest.tapByKey(tester, 'add');
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigDetailScreen');

    // Fill form
    await CommonTest.tapByKey(tester, 'Platform');
    await CommonTest.tapByText(tester, 'Email');
    await CommonTest.enterText(tester, 'Daily Limit', '100');
    await CommonTest.enterText(
        tester, 'Credentials (JSON)', '{"test": "data"}');
    await CommonTest.tapByKey(tester, 'Create');

    // Verify creation
    await CommonTest.checkText(tester, 'Configuration created successfully');
    await CommonTest.checkText(tester, 'EMAIL');
    await CommonTest.checkText(tester, 'Daily Limit: 100');

    // Update configuration
    await CommonTest.tapByText(tester, 'EMAIL');
    await CommonTest.enterText(tester, 'Daily Limit', '200');
    await CommonTest.tapByKey(tester, 'Update');

    // Verify update
    await CommonTest.checkText(tester, 'Configuration updated successfully');
    await CommonTest.checkText(tester, 'Daily Limit: 200');
  });
}
