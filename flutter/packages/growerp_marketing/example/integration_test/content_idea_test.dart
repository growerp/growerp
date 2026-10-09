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

import 'package:growerp_marketing_example/router_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_marketing/src/content_idea/integration_test/content_idea_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP content idea test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createMarketingExampleRouter(),
      marketingMenuConfig,
      marketingExampleDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("applicationId"),
      ),
      title: 'GrowERP content idea test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await ContentIdeaTest.selectContent(tester);
    await ContentIdeaTest.addContentIdea(
      tester,
      title: 'Spreadsheets cost hours',
      text: 'Our customers tell us re-keying orders costs them hours a week.',
      url: 'https://www.growerp.com/content/about',
    );
    await ContentIdeaTest.addContentIdea(tester, title: 'One system, six tools');
    ContentIdeaTest.checkIdeas(['Spreadsheets cost hours', 'One system, six tools']);
    await ContentIdeaTest.updateContentIdea(
        tester, index: 0, newTitle: 'Re-keying costs hours');
    ContentIdeaTest.checkIdeas(['Re-keying costs hours', 'One system, six tools']);
    await ContentIdeaTest.toggleIdeas(tester, expectCollapsed: true);
    await ContentIdeaTest.toggleIdeas(tester, expectCollapsed: false);
    await ContentIdeaTest.deleteContentIdea(tester, index: 0);
    ContentIdeaTest.checkIdeas(['One system, six tools']);
    await CommonTest.logout(tester);
  }, skip: false);
}
