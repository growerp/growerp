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

import 'package:growerp_marketing/src/test_data.dart' as assessment_data;
import 'package:growerp_marketing/src/landing_page/integration_test/landing_page_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP landing page test''', (tester) async {
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
      title: 'GrowERP landing page test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await LandingPageTest.selectLandingPages(tester);
    await LandingPageTest.addLandingPages(
      tester,
      assessment_data.landingPages.sublist(0, 3),
    );
    await LandingPageTest.checkLandingPages(tester);
    await LandingPageTest.updateLandingPages(
      tester,
      assessment_data.updatedLandingPages.sublist(0, 3),
    );
    await LandingPageTest.checkLandingPages(tester);
    await LandingPageTest.deleteLandingPages(tester);
  }, skip: false);
  testWidgets('''GrowERP landing page section test''', (tester) async {
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
      title: 'GrowERP landing page section test',
      clear: false,
    );
    await CommonTest.login(tester);
    await LandingPageTest.selectLandingPages(tester);
    await LandingPageTest.addPageSections(
      tester,
      assessment_data.landingPageSections,
    );
    await LandingPageTest.checkPageSections(tester);
    await LandingPageTest.updatePageSections(
      tester,
      assessment_data.updatedLandingPageSections,
    );
    await LandingPageTest.checkPageSections(tester);
    await LandingPageTest.deletePageSection(tester);
  }, skip: false);
  testWidgets('''GrowERP landing page credibility test''', (tester) async {
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
      title: 'GrowERP landing page credibility test',
      clear: false,
    );
    await CommonTest.login(tester);
    await LandingPageTest.selectLandingPages(tester);
    await LandingPageTest.addCredibilityInfo(
      tester,
      assessment_data.credibilityInfo,
    );
    await LandingPageTest.addCredibilityStatistics(
      tester,
      assessment_data.credibilityStatistics,
    );
    await LandingPageTest.checkCredibilityInfo(tester);
    await LandingPageTest.checkCredibilityStatistics(tester);
    await LandingPageTest.updateCredibilityInfo(
      tester,
      assessment_data.updatedCredibilityInfo,
    );
    await LandingPageTest.checkCredibilityInfo(tester);
    await LandingPageTest.checkCredibilityStatistics(tester);
    await LandingPageTest.deleteCredibilityStatistic(tester);
    await LandingPageTest.checkCredibilityStatistics(tester);
    await CommonTest.logout(tester);
  });
}
