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

/// Integration test for the LinkedIn connections CSV lead import.
///
/// Parses the sample export (integration_test/data/linkedin_connections_sample.csv)
/// the same way the dialog does, imports it via the backend, then verifies:
///   - 5 leads created with role Lead (unqualified / CUSTOMER_ASSIGNED)
///   - LinkedIn 'Position' stored as personalTitle
///   - company created when present, NOT duplicated (Alice + Bob share Acme Corp)
///   - a contact without a company (Eve) becomes a lead with no company
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('LinkedIn connections CSV import creates deduped leads', (
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
      title: 'LinkedIn lead import test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // 1. Parse the sample LinkedIn export exactly as the import dialog does.
    final csv = await File(
      'integration_test/data/linkedin_connections_sample.csv',
    ).readAsString();
    final leads = parseLinkedInConnectionsCsv(csv);
    expect(leads.length, 5, reason: '5 data rows -> 5 leads');

    final aliceParsed = leads.firstWhere((l) => l.name == 'Alice Anderson');
    expect(aliceParsed.role, Role.lead);
    expect(aliceParsed.personalTitle, 'CEO', reason: 'Position -> personalTitle');
    expect(aliceParsed.company?.name, 'Acme Corp');
    expect(
      leads.firstWhere((l) => l.name == 'Eve Evans').company,
      isNull,
      reason: 'no Company column -> no related company',
    );

    // 2. Submit the import (runs in the background); returns the submitted count.
    final submitRaw = await restClient.importCompanyUsers(leads);
    final submit = submitRaw is String ? jsonDecode(submitRaw) : submitRaw;
    expect(submit['submitted'], 5, reason: 'submitted record count');

    // 3. Pump the app until the completion notification arrives over the
    //    WebSocket (worker -> NotificationBloc -> global handler -> SnackBar).
    bool sawNotification = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.textContaining('Import complete').evaluate().isNotEmpty) {
        sawNotification = true;
        break;
      }
    }
    expect(
      sawNotification,
      isTrue,
      reason: 'completion notification toast (Import complete: X imported, Y '
          'failed) should be shown',
    );

    // 4. Verify the leads landed in the DB.
    final imported =
        (await restClient.getUser(role: Role.lead, limit: 50)).users;
    expect(
      imported.length,
      greaterThanOrEqualTo(5),
      reason: 'background import should create 5 leads',
    );

    User leadByFirst(String f) =>
        imported.firstWhere((u) => u.firstName == f);

    final alice = leadByFirst('Alice');
    final bob = leadByFirst('Bob');
    final eve = leadByFirst('Eve');

    expect(alice.role, Role.lead, reason: 'unqualified lead');
    expect(alice.personalTitle, 'CEO',
        reason: 'personalTitle round-trips (needs backend restart to pick up '
            'the new view alias)');
    expect(alice.company?.partyId, isNotNull);

    // Alice and Bob both at "Acme Corp" must resolve to the SAME company.
    expect(
      alice.company?.partyId,
      bob.company?.partyId,
      reason: 'company deduped by name, not duplicated',
    );

    // Eve had no company.
    expect(eve.company?.partyId, isNull);

    await CommonTest.logout(tester);
  }, skip: false);
}
