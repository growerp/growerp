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

// Seeds the hosted Tasco demo (tasco.growerp.net) with an agency, its demo book and a
// portal client for the motor policy, and prints the logins:
//   flutter test integration_test/seed_hosted_demo_test.dart -d linux \
//     --dart-define=BACKEND_URL=https://tasco-backend.growerp.net

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:insurance/main.dart';
import 'package:integration_test/integration_test.dart';

import 'demo_video_test.dart' show createDemoRouter, demoMenuConfig;

/// email of the first account on a fresh server, whose GROWERP setup is unfinished
const _growerpAdmin = String.fromEnvironment('GROWERP_ADMIN');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('seed hosted demo', (tester) async {
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
    // a fresh server: the first registration claimed the GROWERP system company,
    // finish its setup (as CI's registration_scenarios_test scenario A does)
    if (_growerpAdmin.isNotEmpty) {
      await CommonTest.pressLoginButton(tester);
      await CommonTest.enterText(tester, 'username', _growerpAdmin);
      await CommonTest.enterText(tester, 'password', 'qqqqqq9!');
      await CommonTest.pressLogin(tester);
      await CommonTest.waitForKey(tester, 'companyName');
      await CommonTest.tapByKey(tester, 'submit');
      for (var i = 0; i < 300; i++) {
        if (tester.any(find.byKey(const Key('HomeFormAuth')))) break;
        await tester.pump(const Duration(seconds: 1));
      }
      await CommonTest.logout(tester);
    }
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    final admin = (await PersistFunctions.getTest()).admin!;
    final motor = (await restClient.getPolicies(
      search: '51K-238',
    )).policies.first;
    final clientEmail = 'lan.${CommonTest.getRandom()}@example.com';
    await restClient.createUser(
      user: User(
        firstName: 'Lan',
        lastName: 'Nguyen',
        email: clientEmail,
        loginName: clientEmail,
        role: Role.customer,
        userGroup: UserGroup.other,
        company: Company(partyId: motor.insuredPartyId, name: motor.insuredName),
      ),
      password: 'qqqqqq9!',
    );
    print('DEMO_AGENT ${admin.email} qqqqqq9!');
    print('DEMO_CLIENT $clientEmail qqqqqq9!');
    print('DEMO_VERIFY ${motor.verificationUrl}');
  });
}
