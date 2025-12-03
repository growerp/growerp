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

import 'package:marketing_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_marketing/src/test_data.dart' as assessment_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP landing page test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
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
      generateRoute,
      testMenuOptions,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
      ),
      title: 'GrowERP landing page section test',
      clear: false,
    );
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
      generateRoute,
      testMenuOptions,
      const [],
      restClient: restClient,
      blocProviders: getExampleBlocProviders(
        restClient,
        GlobalConfiguration().get("classificationId"),
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
