import 'package:flutter/material.dart';
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
      app.createOutreachExampleRouter(),
      app.outreachMenuConfig,
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
        tester, '/platforms', 'PlatformConfigListScreen');

    // Tap the first platform row (email at index 0) to open detail dialog
    await CommonTest.tapByKey(tester, 'platform0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify detail dialog opened
    expect(
      find.byKey(const Key('PlatformConfigDetail_email')),
      findsOneWidget,
      reason: 'Platform config detail dialog for email should be open',
    );

    // Fill form fields
    await CommonTest.enterText(tester, 'Daily Limit', '100');
    await tester.ensureVisible(find.byKey(const Key('API Key')));
    await CommonTest.enterText(tester, 'API Key', 'test-api-key');

    // Tap Create button (no existing config)
    await tester.ensureVisible(find.byKey(const Key('Create')));
    await CommonTest.tapByKey(tester, 'Create');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Dialog should have closed after successful create
    // Verify we're back on the list screen
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    // Re-open the email config to verify and update
    await CommonTest.tapByKey(tester, 'platform0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify the saved values
    expect(
      CommonTest.getTextFormField('Daily Limit'),
      equals('100'),
    );

    // Update the daily limit
    await CommonTest.enterText(tester, 'Daily Limit', '200');

    // Tap Update button (existing config)
    await tester.ensureVisible(find.byKey(const Key('Update')));
    await CommonTest.tapByKey(tester, 'Update');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify we're back on the list screen
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    // Verify the update by re-opening the email config
    await CommonTest.tapByKey(tester, 'platform0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    expect(
      CommonTest.getTextFormField('Daily Limit'),
      equals('200'),
      reason: 'Daily limit should be updated to 200',
    );

    // Close dialog
    await CommonTest.tapByKey(tester, 'cancel');
    await tester.pumpAndSettle();

    await CommonTest.logout(tester);
  });
}
