/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:growerp_outreach_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_marketing/growerp_marketing.dart';

/// Approving an EMAIL-only campaign must be handled entirely by the backend:
/// process#CampaignAutomation drains the PENDING messages through the company's
/// own SMTP server. No browser automation may start and no duplicate messages
/// may be created. Once nothing is left to send the campaign closes itself
/// (MKTG_CAMP_COMPLETED, isActive N) instead of sitting In Progress forever.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('approving an EMAIL campaign sends via the backend', (
    tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOutreachExampleRouter(),
      outreachMenuConfig,
      const [],
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
      title: 'Outreach email approve test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await OutreachCampaignTest.enablePlatforms(restClient, ['EMAIL']);

    // 1. An EMAIL-only campaign with two recipients waiting to be sent.
    final campaign = await restClient.createOutreachCampaign(campaign: {
      'campaignName': 'Email approve test',
      'platforms': '["EMAIL"]',
      'emailSubject': 'Hello from GrowERP',
      'messageTemplate': 'Hi {name}, can we talk?',
      'dailyLimitPerPlatform': 50,
    });
    final campaignId = campaign.campaignId!;

    await restClient.importOutreachRecipients(
      marketingCampaignId: campaignId,
      defaultPlatform: 'EMAIL',
      recipients: [
        {
          'recipientName': 'Alice Anderson',
          'recipientEmail': 'alice@example.com',
          'platform': 'EMAIL',
        },
        {
          'recipientName': 'Bob Brown',
          'recipientEmail': 'bob@example.com',
          'platform': 'EMAIL',
        },
      ],
    );

    final pending = (await restClient.listOutreachMessages(
      marketingCampaignId: campaignId,
    ))
        .messages;
    expect(pending.length, 2);
    expect(pending.every((m) => m.status == 'PENDING'), isTrue);

    // 2. Approve exactly as the detail screen does.
    OutreachCampaignBloc(restClient).add(
      OutreachCampaignUpdate(
        campaignId: campaignId,
        status: 'MKTG_CAMP_APPROVED',
      ),
    );

    // 3. The backend drain runs in the background: poll until both messages
    //    leave PENDING.
    List<OutreachMessage> messages = [];
    for (var i = 0; i < 30; i++) {
      await tester.pumpAndSettle(const Duration(seconds: 1));
      messages = (await restClient.listOutreachMessages(
        marketingCampaignId: campaignId,
      ))
          .messages;
      if (messages.every((m) => m.status != 'PENDING')) break;
    }

    // No extra rows: the backend updates the existing PENDING messages.
    expect(messages.length, 2, reason: 'approve created duplicate messages');

    for (final message in messages) {
      // A backend without SMTP settings fails permanently, so the message is
      // FAILED on the first attempt rather than kept PENDING for a retry.
      expect(message.status, isNot('PENDING'),
          reason: '${message.recipientName} was never processed');
      if (message.status == 'FAILED') {
        // Without SMTP settings the send has to fail cleanly on the message,
        // not blow up the campaign.
        expect(message.errorMessage, isNotNull);
        expect(message.attemptCount, greaterThan(0),
            reason: 'a processed message must record its attempt');
      } else {
        expect(message.status, 'SENT');
        expect(message.sentDate, isNotNull);
      }
    }

    // 4. Nothing left to send, so the campaign closed itself.
    final detail = await restClient.getOutreachCampaignDetail(
      marketingCampaignId: campaignId,
    );
    expect(detail.campaign.status, 'MKTG_CAMP_COMPLETED',
        reason: 'campaign not completed after its last message was processed');
    expect(detail.campaign.isActive, 'N');

    await CommonTest.logout(tester);
  }, skip: false);
}
