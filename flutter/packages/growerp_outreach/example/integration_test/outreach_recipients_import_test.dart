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

import 'dart:convert';
import 'dart:io';
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

/// Integration test for import#OutreachRecipients' template personalization.
///
/// Imports the sample LinkedIn CSV as campaign recipients with a
/// {name}/{company}/{title} template and verifies each OutreachMessage's
/// messageContent is fully substituted server-side. A second campaign checks
/// the {landingPageUrl} placeholder: the campaign's landing page is resolved to
/// its public url and baked into the message at import time, which is what the
/// client-sent platforms (LINKEDIN) rely on.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('import#OutreachRecipients personalizes messageContent from template', (
    tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOutreachExampleRouter(),
      outreachMenuConfig,
      outreachExampleDelegates,
      restClient: restClient,
      blocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'Outreach recipients import test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // 1. Create a campaign with a {name}/{company}/{title} LinkedIn template.
    final campaign = await restClient.createOutreachCampaign(campaign: {
      'campaignName': 'Recipients import test',
      'platforms': '["LINKEDIN"]',
      'messageTemplate':
          "Hi {name} — noticed you're {title} at {company}, wanted to connect.",
    });
    expect(campaign.campaignId, isNotNull);

    // 2. Parse the sample CSV exactly as the import dialog does, and map to
    //    the recipients-map shape the dialog sends to importOutreachRecipients.
    final csv = await File(
      'integration_test/data/linkedin_connections_sample.csv',
    ).readAsString();
    final leads = parseLinkedInConnectionsCsv(csv);
    expect(leads.length, 5);

    final recipients = leads
        .map((l) => {
              'recipientName': l.name,
              'recipientProfileUrl': l.url,
              'recipientEmail': l.email,
              'recipientCompany': l.company?.name,
              'recipientTitle': l.personalTitle,
              'platform': 'LINKEDIN',
            })
        .toList();

    final importRaw = await restClient.importOutreachRecipients(
      marketingCampaignId: campaign.campaignId,
      recipients: recipients,
    );
    final importResult = importRaw is String ? jsonDecode(importRaw) : importRaw;
    expect(importResult['importedCount'], 5);
    expect(importResult['skippedCount'], 0);

    // 3. Verify each message's content was personalized server-side.
    final messages = (await restClient.listOutreachMessages(
      marketingCampaignId: campaign.campaignId,
    ))
        .messages;
    expect(messages.length, 5);

    OutreachMessage byName(String name) =>
        messages.firstWhere((m) => m.recipientName == name);

    final alice = byName('Alice Anderson');
    expect(alice.status, 'PENDING');
    expect(alice.recipientCompany, 'Acme Corp');
    expect(alice.recipientTitle, 'CEO');
    expect(alice.messageContent, contains('Alice Anderson'));
    expect(alice.messageContent, contains('Acme Corp'));
    expect(alice.messageContent, contains('CEO'));
    expect(alice.messageContent, isNot(contains('{name}')));
    expect(alice.messageContent, isNot(contains('{company}')));
    expect(alice.messageContent, isNot(contains('{title}')));

    // Eve has no company — {company} should resolve to empty, not "null".
    final eve = byName('Eve Evans');
    expect(eve.recipientCompany, anyOf(isNull, isEmpty));
    expect(eve.messageContent, contains('Eve Evans'));
    expect(eve.messageContent, contains('Consultant'));
    expect(eve.messageContent, isNot(contains('null')));
    expect(eve.messageContent, isNot(contains('{company}')));

    // 4. {landingPageUrl}: a campaign with a landing page substitutes its
    //    public url, {tenantBaseUrl}/landing/{pseudoId}.
    final landingPage = await restClient.createLandingPage(
      title: 'Recipients import landing',
      pseudoId: 'recipients-import-landing',
    );
    expect(landingPage.landingPageId, isNotNull);

    final linkCampaign = await restClient.createOutreachCampaign(campaign: {
      'campaignName': 'Recipients import link test',
      'platforms': '["LINKEDIN"]',
      'landingPageId': landingPage.landingPageId,
      'messageTemplate': 'Hi {firstName}, have a look: {landingPageUrl}',
    });

    await restClient.importOutreachRecipients(
      marketingCampaignId: linkCampaign.campaignId,
      recipients: [
        {
          'recipientName': 'Alice Anderson',
          'recipientProfileUrl': 'https://www.linkedin.com/in/alice-anderson',
          'platform': 'LINKEDIN',
        }
      ],
    );

    final linkMessages = (await restClient.listOutreachMessages(
      marketingCampaignId: linkCampaign.campaignId,
    ))
        .messages;
    expect(linkMessages.length, 1);
    expect(linkMessages.first.messageContent,
        contains('/landing/recipients-import-landing'));
    expect(linkMessages.first.messageContent,
        isNot(contains('{landingPageUrl}')));

    // the campaign itself reports the url, which is what the campaign detail
    // screen shows and the LinkedIn send queue substitutes with
    final fetched = (await restClient.listOutreachCampaigns())
        .campaigns
        .firstWhere((c) => c.campaignId == linkCampaign.campaignId);
    expect(fetched.landingPageId, landingPage.landingPageId);
    expect(fetched.landingPageUrl, contains('/landing/recipients-import-landing'));

    // an empty landingPageId clears the page (null would keep it, like every
    // other field of a partial update)
    await restClient.updateOutreachCampaign(campaign: {
      'marketingCampaignId': linkCampaign.campaignId,
      'landingPageId': '',
    });
    final cleared = (await restClient.listOutreachCampaigns())
        .campaigns
        .firstWhere((c) => c.campaignId == linkCampaign.campaignId);
    expect(cleared.landingPageId, anyOf(isNull, isEmpty));
    expect(cleared.landingPageUrl, anyOf(isNull, isEmpty));

    await CommonTest.logout(tester);
  }, skip: false);
}
