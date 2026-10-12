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

// ignore_for_file: depend_on_referenced_packages, avoid_print

// Staff scenes of the renewal demo video (demo_video/record_renewal.sh): the
// cockpit with scores and funnel, an AI-drafted Zalo reminder sent, then -
// while demo_video/record_web.js records the customer's side (message,
// renewal page, AI call) - the telesales queue with the AI hand-over and the
// funnel. Scenes print SCENE_START/SCENE_END <id> <epoch ms>; the time in
// between is cut. Needs a local backend with real AI.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:insurance/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_video_test.dart' show createDemoRouter, demoMenuConfig;

const _demoDir = String.fromEnvironment('DEMO_DIR', defaultValue: 'demo_video');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('insurance renewal demo video', (tester) async {
    final out = '$_demoDir/out_renewal';
    final durations = Map<String, dynamic>.from(
      jsonDecode(File('$out/durations.json').readAsStringSync()),
    );

    Future<void> hold(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    }

    Future<void> scene(String id, Future<void> Function() body) async {
      final start = DateTime.now().millisecondsSinceEpoch;
      print('SCENE_START $id $start');
      await body();
      final spent = DateTime.now().millisecondsSinceEpoch - start;
      await hold(((durations[id] as int) + 700 - spent).clamp(700, 60000));
      print('SCENE_END $id ${DateTime.now().millisecondsSinceEpoch}');
    }

    Future<void> tap(String key) async {
      await CommonTest.tapByKey(tester, key);
      await hold(500);
    }

    /// tap row [index] of a StyledDataTable, scrolling it into view first
    Future<void> tapRow(String listKey, int index) async {
      final row = find.byKey(Key('item$index'));
      if (!tester.any(row)) {
        await tester.scrollUntilVisible(
          row,
          120,
          scrollable: find
              .descendant(
                of: find.byKey(Key(listKey)),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }
      await hold(400);
      await tap('item$index');
    }

    Future<void> scrollTo(String dialogKey, String key) async {
      final finder = find.byKey(Key(key));
      final list = find.descendant(
        of: find.byKey(Key(dialogKey)),
        matching: find.byType(Scrollable),
      );
      for (var i = 0; i < 60 && !tester.any(finder); i++) {
        if (tester.any(list)) {
          await tester.drag(list.first, Offset(0, i < 30 ? -150 : 150));
        }
        await hold(250);
      }
      if (tester.any(finder)) {
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
      }
      await hold(300);
    }

    final restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createDemoRouter(),
      demoMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getInsuranceAppBlocProviders(restClient, 'AppInsurance'),
      applicationId: 'AppInsurance',
      clear: true,
      title: 'GrowERP Insurance',
    );

    // --- setup (cut): an agency with its synthetic renewal book
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    // a realistic agency name in the customer's messages and pages
    final company = tester
        .element(find.byType(Navigator).first)
        .read<AuthBloc>()
        .state
        .authenticate
        ?.company;
    if (company != null) {
      await restClient.updateCompany(
        company: company.copyWith(name: 'Saigon Auto Insurance'),
      );
    }
    await CommonTest.selectOption(tester, '/renewalCockpit', '/renewalCockpit');
    await CommonTest.waitForKey(tester, 'name0');

    await scene('cockpit', () async {
      await hold(3500);
      await tap('bandHigh');
      await hold(2500);
      await tap('bandAll');
    });

    final candidates = (await restClient.getRenewalCandidates(
      limit: 300,
    )).candidates;
    // the customer whose reminder we draft: the best one a reminder is due for
    final remind = candidates.firstWhere(
      (c) =>
          c.nextAction == 'Send reminder' && c.nextChannelEnumId == 'InchZalo',
    );
    final remindIndex = candidates.indexOf(remind);

    await scene('dialog', () async {
      await tapRow('renewalList', remindIndex);
      await CommonTest.waitForKey(tester, 'RenewalCandidateDialog');
      await hold(2500);
      await scrollTo('RenewalCandidateDialog', 'aiDraft');
      await tap('aiDraft');
      for (var i = 0; i < 60; i++) {
        final field = tester.widget<TextField>(
          find.byKey(const Key('messageText')),
        );
        if ((field.controller?.text ?? '').isNotEmpty) break;
        await hold(500);
      }
      await hold(2500);
      await scrollTo('RenewalCandidateDialog', 'sendMessage');
      await tap('sendMessage');
      await CommonTest.waitForSnackbarToGo(tester);
    });
    await tap('cancel');

    // --- (cut) links for the customer's side, recorded by record_web.js
    final touches = (await restClient.getRenewalTouches(
      policyId: remind.policyId,
    )).touches;
    final sentTouch = touches.firstWhere((t) => t.eventEnumId == 'InevSent');
    var link = await restClient.getRenewalLink(policyId: remind.policyId);
    if (link is String) link = jsonDecode(link);
    final base = (link['renewalUrl'] as String).split('/renew/').first;
    // a second customer gets the AI call
    final call = candidates.firstWhere(
      (c) =>
          c.policyId != remind.policyId &&
          c.band != 'Done' &&
          c.band != 'Stop' &&
          (c.consentChannels ?? []).contains('InchCall'),
    );
    var callLink = await restClient.getRenewalLink(policyId: call.policyId);
    if (callLink is String) callLink = jsonDecode(callLink);
    File('$out/links.json').writeAsStringSync(
      jsonEncode({
        'previewUrl': '$base/message/${sentTouch.touchId}',
        'renewalUrl': '${link['renewalUrl']}?t=${sentTouch.touchId}',
        'plate': remind.vehiclePlate,
        'voiceCallUrl': callLink['voiceCallUrl'],
        'callPlate': call.vehiclePlate,
        'callName': call.insuredName,
      }),
    );
    print('LINKS_READY');
    final done = File('$out/web_done');
    for (var i = 0; i < 1200 && !done.existsSync(); i++) {
      await hold(500);
    }

    await CommonTest.selectOption(
      tester,
      '/renewalCockpit',
      '/renewalCockpit',
      'Telesales',
    );
    await CommonTest.waitForKey(tester, 'qname0');

    await scene('telesales', () async {
      await hold(2500);
      final queue = (await restClient.getTelesalesQueue()).queue;
      final index = queue.indexWhere((c) => c.policyId == call.policyId);
      await tapRow('telesalesList', index < 0 ? 0 : index);
      await CommonTest.waitForKey(tester, 'TelesalesDialog');
      await hold(4000);
      if (tester.any(find.byKey(const Key('transcript')))) {
        await tap('transcript');
        await hold(3000);
      }
      await scrollTo('TelesalesDialog', 'recordOutcome');
      await tap('recordOutcome');
      await CommonTest.waitForSnackbarToGo(tester);
    });

    await CommonTest.selectOption(
      tester,
      '/renewalCockpit',
      '/renewalCockpit',
      'Cockpit',
    );
    await CommonTest.waitForKey(tester, 'name0');

    await scene('impact', () async {
      await hold(1500);
    });
  });
}
