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
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'liner_test_app.dart';

// ── Test data ─────────────────────────────────────────────────────────────────

final List<LinerType> panelTestLinerTypes = [
  LinerType(
    linerName: '60 mil HDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.306'),
  ),
];

final List<Product> panelTestProducts = [
  Product(
    pseudoId: 'LINER-ROLL-60',
    productName: '60mil HDPE Roll Stock',
    productTypeId: 'Physical Good',
    price: Decimal.parse('1.50'),
    listPrice: Decimal.parse('1.75'),
  ),
  Product(
    pseudoId: 'LINER-SYS-60',
    productName: 'Pond Liner System 60mil',
    productTypeId: 'Physical Good',
    price: Decimal.parse('2.00'),
    listPrice: Decimal.parse('2.40'),
  ),
];

// The work order product autocomplete only lists products that have a BOM
// (WorkOrderDialog uses getBoms), so LINER-SYS-60 needs one.
final List<BomItem> panelTestBomItems = [
  BomItem(
    productId: 'LINER-SYS-60',
    toProductId: 'LINER-ROLL-60',
    quantity: Decimal.parse('1'),
  ),
];

final List<LinerPanel> panelTestPanels = [
  LinerPanel(
    linerTypeId: '60 mil HDPE',
    panelName: 'Panel A',
    panelWidth: Decimal.parse('45'),
    panelLength: Decimal.parse('100'),
  ),
  LinerPanel(
    linerTypeId: '60 mil HDPE',
    panelName: 'Panel B',
    panelWidth: Decimal.parse('22.5'),
    panelLength: Decimal.parse('50'),
  ),
];

// ── Test ──────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP LinerPanel test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createLinerExampleRouter(),
      linerExampleMenuConfig,
      linerExampleDelegates,
      restClient: restClient,
      blocProviders: [
        ...getManufacturingBlocProviders(restClient),
        ...getCatalogBlocProviders(restClient, 'AppAdmin'),
        ...getLinerBlocProviders(restClient),
      ],
      title: 'LinerPanel test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        'products': panelTestProducts,
        'bomItems': panelTestBomItems,
      },
    );

    // Set up liner types so the panel dialog's dropdown is populated.
    await LinerTypeTest.selectLinerTypes(tester);
    await LinerTypeTest.addLinerTypes(tester, panelTestLinerTypes);

    // Create a work order directly (no sales order needed for this focused test).
    await WorkOrderTest.selectWorkOrders(tester);
    await WorkOrderTest.addWorkOrders(tester, [
      WorkOrder(
        productPseudoId: 'LINER-SYS-60',
        estimatedQuantity: Decimal.parse('1'),
      ),
    ]);

    // Open the work order — liner panel tab is embedded via extraTabBuilder.
    await WorkOrderTest.openWorkOrder(tester, 0);

    // Add two liner panels and verify QC numbers are generated.
    await LinerPanelTest.addLinerPanels(tester, panelTestPanels);
    await LinerPanelTest.checkLinerPanels(tester, panelTestPanels.length);

    // Open the first panel and verify computed fields are present.
    await LinerPanelTest.checkComputedFields(tester, 0);

    // Delete the second panel.
    await LinerPanelTest.deleteLinerPanel(tester, 1);

    // Close the work order dialog.
    if (await CommonTest.doesExistKey(tester, 'cancel')) {
      await CommonTest.tapByKey(tester, 'cancel');
    }

    await CommonTest.logout(tester);
  });
}
