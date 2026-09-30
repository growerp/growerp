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

// Scripted run of the insurance app for the Tasco challenge demo video, recorded by
// demo_video/record.sh and cut by demo_video/assemble.sh. Every scene prints
// `SCENE_START <id> <epoch ms>` / `SCENE_END <id> <epoch ms>` and lasts at least as long as
// its voiceover (demo_video/out/durations.json); setup between scenes is cut out.
// Needs a local backend with real AI (no GROWERP_TEST_MODE), see demo_video/README.md.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_insurance/growerp_insurance.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:insurance/main.dart';
import 'package:insurance/views/insurance_db_form.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _demoDir = String.fromEnvironment('DEMO_DIR', defaultValue: 'demo_video');
const _plate = '51K-238.46';

const _menuConfig = MenuConfiguration(
  menuConfigurationId: 'INSURANCE_DEFAULT',
  appId: 'insurance',
  name: 'Insurance',
  menuItems: [],
);

GoRouter _router() {
  WidgetRegistry.clear();
  for (final reg in insuranceWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_menuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'INSURANCE_DEFAULT',
      dashboardBuilder: () => const InsuranceDbForm(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Insurance',
    ),
  );
}

/// The "native" picker hands out the demo photos one after the other.
final class _DemoFile extends PlatformFile {
  _DemoFile(this._path);
  final String _path;
  @override
  String get name => _path.split('/').last;
  @override
  Uri get uri => Uri.file(_path);
  @override
  XFile get xFile => XFile(_path);
  @override
  int? lengthSync() => File(_path).lengthSync();
  @override
  Future<int> length() => File(_path).length();
  @override
  Future<Uint8List> readAsBytes() => File(_path).readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      File(_path).openRead().map((c) => Uint8List.fromList(c));
}

class _DemoPicker extends FilePickerPlatform {
  _DemoPicker(this.photos);
  final List<String> photos;
  int _next = 0;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => _DemoFile(photos[_next++ % photos.length]);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const applicationId = 'AppInsurance';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('insurance demo video', (tester) async {
    final durations = Map<String, dynamic>.from(
      jsonDecode(File('$_demoDir/out/durations.json').readAsStringSync()),
    );
    final photoDir = Directory('$_demoDir/photos');
    final photos = photoDir.listSync().map((f) => f.absolute.path).toList()
      ..sort();
    FilePickerPlatform.instance = _DemoPicker(photos);

    /// real time passes, the app keeps drawing
    Future<void> hold(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    }

    /// a scene lasts at least its voiceover plus a short breath
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

    Future<void> type(String key, String text) async {
      await CommonTest.enterText(tester, key, text);
      await hold(400);
    }

    /// bring [key] into view in the dialog's list; parts of a dialog load
    /// later (claim details), so keep looking a while
    Future<void> scrollTo(String dialogKey, String key) async {
      final finder = find.byKey(Key(key));
      final list = find.descendant(
        of: find.byKey(Key(dialogKey)),
        matching: find.byType(Scrollable),
      );
      for (var i = 0; i < 60 && !tester.any(finder); i++) {
        if (tester.any(list)) {
          await tester.drag(list.first, const Offset(0, -150));
        }
        await hold(250);
      }
      if (tester.any(finder)) {
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
      }
      await hold(300);
    }

    void setLocale(String code) {
      tester
          .element(find.byType(Navigator).first)
          .read<LocaleBloc>()
          .add(LocaleChanged(Locale(code)));
    }

    final restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      _router(),
      _menuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getInsuranceAppBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'GrowERP Insurance',
    );

    // --- setup (cut): an agency with its demo book
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    final motor = (await restClient.getPolicies(search: _plate)).policies.first;
    final random = CommonTest.getRandom();
    final clientEmail = 'lan$random@example.com';
    await restClient.createUser(
      user: User(
        firstName: 'Lan',
        lastName: 'Nguyen',
        email: clientEmail,
        loginName: clientEmail,
        role: Role.customer,
        userGroup: UserGroup.other,
        company: Company(
          partyId: motor.insuredPartyId,
          name: motor.insuredName,
        ),
      ),
      password: 'qqqqqq9!',
    );
    // the public proof page for the phone still in the video
    File(
      '$_demoDir/out/verify_url.txt',
    ).writeAsStringSync(motor.verificationUrl ?? '');

    await scene('title', () async {
      await CommonTest.showDemoStep(
        tester,
        'GrowERP Insurance',
        'Easy to buy · easy to carry · easy to claim\nTasco × GenAI Fund: AI for Insurance',
        seconds: ((durations['title'] as int) / 1000).ceil(),
      );
    });

    await scene('staff', () async {
      await CommonTest.selectOption(tester, '/policies', '/policies');
      await hold(4000);
      await CommonTest.selectOption(
        tester,
        '/policies',
        '/policies',
        'Renewals',
      );
      await hold(3000);
      await CommonTest.selectOption(tester, '/claims', '/claims');
    });

    // --- the client, in Vietnamese
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    setLocale('vi');
    await hold(500);
    await CommonTest.login(tester, username: clientEmail, password: 'qqqqqq9!');
    await MyPoliciesTest.selectMyPolicies(tester);
    final cardIndex = List.generate(6, (i) => i).firstWhere(
      (i) =>
          tester.any(find.byKey(Key('myPolicyTitle$i'))) &&
          CommonTest.getTextField('myPolicyTitle$i').contains(_plate),
    );

    await scene('card', () async {
      await hold(2500);
      await tap('myPolicyCard$cardIndex');
      await CommonTest.waitForKey(tester, 'PolicyCardDialog');
    });

    await scene('explain', () async {
      await scrollTo('PolicyCardDialog', 'explainPolicy');
      await tap('explainPolicy');
      await CommonTest.waitForKey(tester, 'plainSummary');
      await scrollTo('PolicyCardDialog', 'plainSummary');
    });
    await tap('cancel');

    await scene('claim', () async {
      await tap('addNew');
      await CommonTest.waitForKey(tester, 'ClaimWizardDialog');
      await CommonTest.selectDropDown(tester, 'wizardPolicy', _plate);
      await tap('incidentType0');
      await tap('wizardNext');
      // the incident date defaults to today
      await type('incidentLocation', 'Nguyễn Văn Linh, Quận 7, TP.HCM');
      await type(
        'description',
        'Tôi dừng đèn đỏ thì bị một xe sedan màu bạc tông vào đuôi xe.',
      );
      await tap('wizardNext');
      for (var slot = 0; slot < 4; slot++) {
        await scrollTo('ClaimWizardDialog', 'photo$slot');
        await tap('photo$slot');
        await hold(300);
      }
      await hold(1500);
      await scrollTo('ClaimWizardDialog', 'wizardNext');
      await tap('wizardNext');
      await scrollTo('ClaimWizardDialog', 'amountClaimed');
      await type('amountClaimed', '8000000');
      await scrollTo('ClaimWizardDialog', 'consent');
      await tap('consent');
      await scrollTo('ClaimWizardDialog', 'wizardSubmit');
      await CommonTest.tapByKey(tester, 'wizardSubmit', seconds: 5);
      await CommonTest.waitForSnackbarToGo(tester);
      expect(
        find.byKey(const Key('ClaimWizardDialog')),
        findsNothing,
        reason: 'the claim was not accepted',
      );
    });

    // --- (cut) the vision model triages the photos in the background
    final claimId = (await restClient.getClaims(limit: 1)).claims.first.claimId;
    for (var i = 0; i < 90; i++) {
      final claim = (await restClient.getClaims(claimId: claimId)).claims.first;
      if (claim.status == ClaimStatus.aiAssessed) break;
      await hold(1000);
    }
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    setLocale('en');
    await hold(500);
    await CommonTest.login(tester);
    await CommonTest.selectOption(tester, '/claims', '/claims');

    await scene('triage', () async {
      await tap('item0');
      await CommonTest.waitForKey(tester, 'ClaimDialog');
      await scrollTo('ClaimDialog', 'claimPhotos');
      await hold(4000);
      await scrollTo('ClaimDialog', 'aiAssessment');
    });

    await scene('filed', () async {
      await scrollTo('ClaimDialog', 'status');
      await CommonTest.selectDropDown(tester, 'status', ClaimStatus.filed.name);
      await type('claimNumber', 'HM-CL-${random.toString().substring(0, 4)}');
      await scrollTo('ClaimDialog', 'update');
      await CommonTest.tapByKey(tester, 'update', seconds: 3);
    });

    // --- the client again
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.logout(tester);
    setLocale('vi');
    await hold(500);
    await CommonTest.login(tester, username: clientEmail, password: 'qqqqqq9!');
    await MyPoliciesTest.selectMyPolicies(tester);

    await scene('timeline', () async {
      await tap('item0');
      await CommonTest.waitForKey(tester, 'ClaimDialog');
      await scrollTo('ClaimDialog', 'claimTimeline');
    });
    await tap('cancel');

    await scene('assistant', () async {
      await tap('askAssistant');
      await CommonTest.waitForKey(tester, 'InsuranceAssistantDialog');
      await type(
        'assistantQuestion',
        'Bảo hiểm xe của tôi hết hạn khi nào và hồ sơ bồi thường đến đâu rồi?',
      );
      await CommonTest.tapByKey(tester, 'assistantSend', seconds: 2);
      await CommonTest.waitForKey(tester, 'assistantMessage1');
    });
    await tap('cancel');

    await scene('close', () async {
      await CommonTest.showDemoStep(
        tester,
        'People decide. AI assists.',
        'Consent and minimal data by design · no price incentives\n'
            'Ready for a 4-week pilot with Tasco · GrowERP, open source',
        seconds: ((durations['close'] as int) / 1000).ceil(),
      );
    });
  });
}
