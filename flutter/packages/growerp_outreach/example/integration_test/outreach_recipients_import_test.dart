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
/// messageContent is fully substituted server-side.
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
      const [],
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

    await CommonTest.logout(tester);
  }, skip: false);
}
