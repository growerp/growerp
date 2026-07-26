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
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:website_example/router_builder.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_website/src/website/integration_test.dart/website_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/website', 'WebsiteDialog');
  }

  var testName = '''GrowERP website test''';
  testWidgets(testName, (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createWebsiteExampleRouter(),
      websiteMenuConfig,
      WebsiteLocalizations.localizationsDelegates,
      title: testName,
      restClient: restClient,
      blocProviders: getWebsiteBlocProviders(restClient),
      clear: true,
    ); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        // related categories also created
        "products": products.sublist(0, 2),
      },
    );
    await selectWebsite(tester);
    await WebsiteTest.updateWeburl(tester);
    await WebsiteTest.updateTitle(tester);
    await WebsiteTest.updateFollowUs(tester);
    await WebsiteTest.updateThemeColors(tester);
    await WebsiteTest.updateTextSection(tester);
    await WebsiteTest.checkTextSectionPubliclyUpdated(tester, restClient);
    await WebsiteTest.updateFtlSection(tester, restClient);
    await WebsiteTest.updateImages(tester);
    await WebsiteTest.updateHomePageCategories(tester, "Deals", products);
    await WebsiteTest.updateHomePageCategories(tester, "Featured", products);
    await WebsiteTest.updateShopCategories(tester);
    await CommonTest.logout(tester);
  });
}
