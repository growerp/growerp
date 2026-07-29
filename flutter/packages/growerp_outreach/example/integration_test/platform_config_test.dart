import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_outreach_example/router_builder.dart' as app;
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

    // Tap the linkedIn platform row (index 1 in OutreachPlatform.values) to
    // open the detail dialog: email (index 0) shows no credential fields,
    // it sends through the company SMTP server.
    await CommonTest.tapByKey(tester, 'platform1');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify detail dialog opened
    expect(
      find.byKey(const Key('PlatformConfigDetail_linkedIn')),
      findsOneWidget,
      reason: 'Platform config detail dialog for linkedIn should be open',
    );

    // Fill form fields
    await CommonTest.enterText(tester, 'Daily Limit', '100');
    await tester.ensureVisible(find.byKey(const Key('API Key')));
    await CommonTest.enterText(tester, 'API Key', 'test-api-key');
    await tester.ensureVisible(find.byKey(const Key('Username')));
    await CommonTest.enterText(tester, 'Username', 'test-user');

    // Tap Create button (no existing config)
    await tester.ensureVisible(find.byKey(const Key('Create')));
    await CommonTest.tapByKey(tester, 'Create');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Dialog should have closed after successful create
    // Verify we're back on the list screen
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    // Re-open the linkedIn config to verify and update
    await CommonTest.tapByKey(tester, 'platform1');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify the saved values
    expect(
      CommonTest.getTextFormField('Daily Limit'),
      equals('100'),
    );
    expect(CommonTest.getTextFormField('API Key'), equals('test-api-key'));
    expect(CommonTest.getTextFormField('Username'), equals('test-user'));

    // Update the daily limit, leaving the credentials untouched
    await CommonTest.enterText(tester, 'Daily Limit', '200');

    // Tap Update button (existing config)
    await tester.ensureVisible(find.byKey(const Key('Update')));
    await CommonTest.tapByKey(tester, 'Update');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    // Verify we're back on the list screen
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    // Verify the update by re-opening the linkedIn config
    await CommonTest.tapByKey(tester, 'platform1');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

    expect(
      CommonTest.getTextFormField('Daily Limit'),
      equals('200'),
      reason: 'Daily limit should be updated to 200',
    );
    // the credentials must survive an update which only changed the limit
    expect(CommonTest.getTextFormField('API Key'), equals('test-api-key'),
        reason: 'API key lost on update');
    expect(CommonTest.getTextFormField('Username'), equals('test-user'),
        reason: 'username lost on update');

    // Close the dialog: it has no cancel button, saving pops it
    await tester.ensureVisible(find.byKey(const Key('Update')));
    await CommonTest.tapByKey(tester, 'Update');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    await CommonTest.logout(tester);
  });
}
