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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_inventory/src/location/integration_test/location_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:inventory_example/router_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP asset test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createInventoryExampleRouter(),
      inventoryMenuConfig,
      InventoryLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getInventoryBlocProviders(restClient, "AppAdmin"),
      title: "Asset test",
      clear: true,
    );
    // Create company and load products (assets need products for association)
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        "products": products.sublist(0, 3), // Load first 3 products for assets
      },
    );

    // First create locations needed for assets
    await CommonTest.selectOption(tester, '/locations', 'LocationList');
    await LocationTest.addLocations(tester, locations.sublist(0, 2));

    // Navigate to assets
    await CommonTest.selectOption(tester, '/assets', 'AssetList');

    // Add assets (using first 3 assets from test data)
    await AssetTest.addAssets(tester, assets.sublist(0, 3));

    // Update assets — change the (updatable) asset name on each record
    await AssetTest.updateAssets(
      tester,
      assets
          .sublist(0, 3)
          .map((a) => a.copyWith(assetName: '${a.assetName} updated'))
          .toList(),
    );

    // Delete (deactivate) the last asset
    await AssetTest.deleteLastAsset(tester);

    await CommonTest.logout(tester);
  });
}
