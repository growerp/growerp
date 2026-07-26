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
import 'package:growerp_catalog/src/product/integration_test/product_test.dart';
import 'package:growerp_catalog/src/category/integration_test/category_test.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  String title = 'GrowERP product test';

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
    await CommonTest.createCompanyAndAdmin(tester);
    // Create categories first via the UI
    await CommonTest.selectOption(tester, '/categories', 'CategoryList');
    await CategoryTest.addCategories(
      tester,
      categories.sublist(0, 2),
      check: false,
    );
    // Now navigate to products
    await CommonTest.selectOption(tester, '/products', 'ProductList');
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, products.sublist(0, 2));
    await ProductTest.updateProducts(tester, products.sublist(2, 4));
    await ProductTest.deleteLastProduct(tester);
    await CommonTest.logout(tester);
  });
}
