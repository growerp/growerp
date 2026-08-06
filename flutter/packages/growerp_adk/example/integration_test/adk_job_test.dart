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

import 'package:adk_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_adk/src/integration_test/adk_test.dart';

import 'adk_test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK scheduled-job test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      adkExampleDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK job test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // Create a scheduled agent — this provisions a backing AdkJob.
    await AdkTest.selectAgents(tester);
    await AdkTest.addAgents(tester, scheduledAgents.sublist(0, 1));

    // The job appears in the Jobs list; pause then resume it.
    await AdkTest.selectJobs(tester);
    await AdkTest.checkJobs(tester);
    await AdkTest.pauseResumeJob(tester);

    // Clean up the scheduled agent.
    await AdkTest.selectAgents(tester);
    await AdkTest.deleteAgents(tester);

    await CommonTest.logout(tester);
  });
}
