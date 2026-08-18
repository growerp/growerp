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

  testWidgets('Outreach setup guide test', (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      app.createOutreachExampleRouter(),
      app.outreachMenuConfig,
      app.outreachExampleDelegates,
      restClient: restClient,
      blocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        BlocProvider<OutreachMessageBloc>(
          create: (context) => OutreachMessageBloc(restClient),
        ),
        BlocProvider<PlatformConfigBloc>(
          create: (context) => PlatformConfigBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
      widgetRegistrations: [
        getOutreachWidgets(),
        getUserCompanyWidgets(),
        getMarketingWidgets(),
      ],
      title: 'Outreach setup guide test',
      clear: true,
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Open the guide
    await CommonTest.selectOption(tester, '/guide', 'OutreachSetupGuide');

    // The first steps are visible without scrolling
    expect(find.byKey(const Key('guideStep0')), findsOneWidget,
        reason: 'first guide step should be present');
    expect(find.byKey(const Key('guideStep1')), findsOneWidget,
        reason: 'platform step should be present');

    // The last step is reachable by scrolling
    await CommonTest.dragUntil(tester, key: 'guideStep8');
    expect(find.byKey(const Key('guideStep8')), findsOneWidget,
        reason: 'last guide step should be reachable');

    // Tapping the platform step shows the platform list inside the app frame
    await CommonTest.dragUntil(tester, key: 'guideStep1');
    await CommonTest.tapByKey(tester, 'guideStep1');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'guideStepPage');
    await CommonTest.checkWidgetKey(tester, 'PlatformConfigListScreen');

    // The back bar returns to the guide, which reloads its state:
    // no platform enabled yet, so the step is still unchecked
    await CommonTest.tapByKey(tester, 'backToGuide');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.checkWidgetKey(tester, 'OutreachSetupGuide');
    expect(
      find.descendant(
        of: find.byKey(const Key('guideStep1')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
      reason: 'platform step should not be marked done without a platform',
    );

    await CommonTest.logout(tester);
  });
}
