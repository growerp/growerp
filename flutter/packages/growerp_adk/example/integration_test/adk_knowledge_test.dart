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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK knowledge-base test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK knowledge test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // Smoke only: adding/editing a knowledge doc chunks + embeds it server-side,
    // which requires a per-company Gemini API key (the same LLM dependency the
    // chat/approval surfaces have). On a keyless CI backend the create 400s, so
    // here we just verify the screen and its controls render. The full
    // add/check/update/delete steps live on AdkTest for key-equipped backends.
    await AdkTest.selectKnowledge(tester);
    await CommonTest.checkWidgetKey(tester, 'addKnowledge');
    await CommonTest.checkWidgetKey(tester, 'refreshKnowledge');

    await CommonTest.logout(tester);
  });
}
