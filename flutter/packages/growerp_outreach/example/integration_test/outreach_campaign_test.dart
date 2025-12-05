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

  testWidgets('''GrowERP outreach campaign test''', (tester) async {
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
      title: 'GrowERP outreach campaign test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await OutreachCampaignTest.selectCampaigns(tester);
    await OutreachCampaignTest.addCampaigns(
      tester,
      test_data.campaigns,
    );
    await OutreachCampaignTest.checkCampaigns(tester, test_data.campaigns);
    await OutreachCampaignTest.updateCampaigns(
      tester,
      test_data.updatedCampaigns,
    );
    await OutreachCampaignTest.checkCampaigns(
        tester, test_data.updatedCampaigns);
    // await OutreachCampaignTest.deleteCampaigns(tester); // Delete not implemented in UI yet
  }, skip: false);
}

class OutreachCampaignTest {
  static Future<void> selectCampaigns(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'Campaigns', 'CampaignListScreen');
  }

  static Future<void> addCampaigns(
      WidgetTester tester, List<OutreachCampaign> campaigns) async {
    for (OutreachCampaign campaign in campaigns) {
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

      // Handle platforms (chips)
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
  }

  static Future<void> checkCampaigns(
      WidgetTester tester, List<OutreachCampaign> campaigns) async {
    for (OutreachCampaign campaign in campaigns) {
      await CommonTest.tapByText(tester, campaign.name);
      // Verify details in dialog
      expect(find.text(campaign.name), findsOneWidget);
      expect(find.text(campaign.targetAudience ?? ''), findsOneWidget);
      expect(find.text(campaign.messageTemplate ?? ''), findsOneWidget);
      expect(find.text(campaign.emailSubject ?? ''), findsOneWidget);
      expect(
          find.text(campaign.dailyLimitPerPlatform.toString()), findsOneWidget);
      // Close dialog by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  }

  static Future<void> updateCampaigns(
      WidgetTester tester, List<OutreachCampaign> campaigns) async {
    for (int i = 0; i < campaigns.length; i++) {
      final originalCampaign = test_data.campaigns[i];
      final campaign = campaigns[i];
      // Tap the row by finding the original name
      await CommonTest.tapByText(tester, originalCampaign.name);

      // Update fields
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

      // Handle platforms (chips)
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

      await CommonTest.tapByText(tester, 'Update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }
}
