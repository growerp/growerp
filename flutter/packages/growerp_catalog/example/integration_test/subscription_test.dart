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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:catalog_example/router_builder.dart';
import 'package:growerp_catalog/src/subscription/integration_test/subscription_test.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  String title = 'GrowERP subscription test';

  testWidgets(title, (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createCatalogExampleRouter(),
      catalogMenuConfig,
      CatalogLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getCatalogBlocProviders(restClient, 'AppAdmin'),
      title: title,
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        "products": subscriptionProducts,
        "categories": categories,
        "companies": customerCompanies,
      },
    );

    // Test subscriptions - add, check, and delete
    await SubscriptionTest.selectSubscriptions(tester);
    await SubscriptionTest.addSubscriptions(
      tester,
      subscriptions.sublist(0, 3),
      check: true,
    );
    await SubscriptionTest.updateSubscriptions(
      tester,
      subscriptions.sublist(3, 6),
    );
    await SubscriptionTest.deleteLastSubscription(tester);

    await CommonTest.logout(tester);
  });
}
