/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:growerp_outreach_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/src/test_data.dart' as test_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP campaign automation test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      menuOptions,
      const [],
      restClient: restClient,
      blocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'GrowERP campaign automation test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await CampaignAutomationTest.selectCampaigns(tester);

    // Create a campaign for testing automation
    final campaign = test_data.campaigns[0];
    await CampaignAutomationTest.addCampaign(tester, campaign);

    // Test Start/Pause Automation
    await CampaignAutomationTest.testAutomationFlow(tester, campaign.name);
  }, skip: false);
}

class CampaignAutomationTest {
  static Future<void> selectCampaigns(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'Campaigns', 'CampaignListScreen');
  }

  static Future<void> addCampaign(
      WidgetTester tester, OutreachCampaign campaign) async {
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.enterText(tester, 'name', campaign.name);
    await CommonTest.tapByKey(tester, 'status');
    await CommonTest.tapByText(tester, campaign.status);
    await CommonTest.enterText(
        tester, 'targetAudience', campaign.targetAudience ?? '');
    await CommonTest.enterText(
        tester, 'messageTemplate', campaign.messageTemplate ?? '');
    await CommonTest.enterText(
        tester, 'emailSubject', campaign.emailSubject ?? '');
    await CommonTest.enterText(
        tester, 'dailyLimit', campaign.dailyLimitPerPlatform.toString());

    if (campaign.platforms.isNotEmpty) {
      final platforms = campaign.platforms
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
      for (var platform in platforms) {
        await CommonTest.tapByText(tester, platform);
      }
    }

    await CommonTest.tapByText(tester, 'Create');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> testAutomationFlow(
      WidgetTester tester, String campaignName) async {
    // Open campaign detail
    await CommonTest.tapByText(tester, campaignName);

    // Check initial state (should be DRAFT or whatever was set)
    // We expect 'Start Automation' button to be visible if status is not ACTIVE
    // But first we might need to ensure status is not ACTIVE.
    // In addCampaign we set it to campaign.status.

    // Let's assume it's DRAFT initially.
    expect(find.text('Start Automation'), findsOneWidget);

    // Tap Start Automation
    await CommonTest.tapByKey(tester, 'automationButton');
    await tester.pumpAndSettle();

    // Verify status changed to ACTIVE and button changed to Pause
    expect(find.text('Pause Automation'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // Wait a bit to simulate automation running (optional)
    await Future.delayed(const Duration(seconds: 2));

    // Tap Pause Automation
    await CommonTest.tapByKey(tester, 'automationButton');
    await tester.pumpAndSettle();

    // Verify status changed to PAUSED and button changed to Start
    expect(find.text('Start Automation'), findsOneWidget);
    expect(find.text('PAUSED'), findsOneWidget);

    // Close dialog
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }
}
