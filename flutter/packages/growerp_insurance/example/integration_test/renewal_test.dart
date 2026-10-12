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

// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_insurance_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';

/// The renewal engine on the synthetic renewal book of the demo data: the
/// cockpit with scores and funnel, a reminder sent on a consented channel,
/// the customer's renewal page (wrong plate refused, confirm, call me), the
/// AI call in test mode, the telesales queue and a call outcome.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Map<String, dynamic> asMap(dynamic r) =>
      Map<String, dynamic>.from(r is String ? jsonDecode(r) : r);

  testWidgets('GrowERP insurance renewal engine', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createInsuranceExampleRouter(),
      insuranceMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppInsurance'),
      applicationId: 'AppInsurance',
      title: "Insurance renewal test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);

    // cockpit: the synthetic book, best first, with the funnel above it
    await CommonTest.selectOption(tester, '/renewalCockpit', 'RenewalCockpit');
    await CommonTest.waitForKey(tester, 'name0');
    final candidates = (await restClient.getRenewalCandidates(
      limit: 300,
    )).candidates;
    expect(candidates.length, greaterThan(40));
    expect(candidates.first.band, isIn(['High', 'Medium']));
    expect(candidates.first.reasons, isNotEmpty);
    expect(find.byKey(const Key('funnel_total')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'item0');
    await CommonTest.waitForKey(tester, 'RenewalCandidateDialog');
    expect(find.byKey(const Key('reason0')), findsOneWidget);
    expect(find.byKey(const Key('nextStep')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'cancel');

    // a reminder on the consented channel the score picked
    final due = candidates.firstWhere(
      (c) => c.nextAction == 'Send reminder' && c.nextChannelEnumId != null,
    );
    final sent = asMap(
      await restClient.sendRenewalReminders(policyIds: [due.policyId]),
    );
    expect(sent['sentCount'], 1);
    final sentItem = Map<String, dynamic>.from((sent['sent'] as List).first);
    expect(sentItem['channelEnumId'], due.nextChannelEnumId);
    expect(sentItem['messageText'], contains('/renew/'));

    // the customer: wrong plate refused, right plate confirmed, asks a call
    final token = RegExp(
      r'/renew/([0-9a-f]+)',
    ).firstMatch(sentItem['renewalUrl'])!.group(1)!;
    final plateEnd = due.vehiclePlate!.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    Future<Map<String, dynamic>> act(String action, String plate) async =>
        asMap(
          await restClient.post(
            'rest/s1/growerp/100/RenewalAction',
            data: {
              'renewalToken': token,
              'action': action,
              'plateEnd': plate,
              't': sentItem['touchId'],
            },
          ),
        );
    expect((await act('confirm', '000'))['ok'], false);
    final last3 = plateEnd.substring(plateEnd.length - 3);
    expect((await act('confirm', last3))['ok'], true);
    expect((await act('callback', last3))['ok'], true);

    // the AI call (test mode: canned understanding, no speech)
    var turn = asMap(
      await restClient.post(
        'rest/s1/growerp/100/VoiceBot',
        data: {'renewalToken': token, 'text': '', 'speak': false},
      ),
    );
    expect(turn['reply'], isNotEmpty);
    expect(turn['done'], false);
    turn = asMap(
      await restClient.post(
        'rest/s1/growerp/100/VoiceBot',
        data: {
          'renewalToken': token,
          'text': 'dừng',
          'stateJson': turn['stateJson'],
          'speak': false,
        },
      ),
    );
    expect(turn['done'], true);
    expect(turn['outcomeEnumId'], 'InocOptOut');

    // telesales: the customers to call, a call recorded as renewed
    final queue = (await restClient.getTelesalesQueue()).queue;
    expect(queue, isNotEmpty);
    await CommonTest.selectOption(tester, '/telesales', 'TelesalesQueue');
    await CommonTest.waitForKey(tester, 'qname0');
    await CommonTest.tapByKey(tester, 'item0');
    await CommonTest.waitForKey(tester, 'TelesalesDialog');
    await CommonTest.tapByKey(tester, 'recordOutcome', seconds: 3);
    await CommonTest.waitForSnackbarToGo(tester);
    final touches = (await restClient.getRenewalTouches(
      policyId: queue.first.policyId,
    )).touches;
    expect(touches.map((t) => t.eventEnumId), contains('InevIssued'));

    // the funnel counts the renewal
    final funnel = asMap(await restClient.getRenewalFunnel());
    expect(funnel['funnel']['stages']['InevRenewed'], greaterThan(0));

    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
  });
}
