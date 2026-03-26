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
    pseudoId: 'LINER-SYS-60',
    productName: 'Pond Liner System 60mil',
    productTypeId: 'GoodsSaleShipped',
    price: Decimal.parse('2.00'),
    listPrice: Decimal.parse('2.40'),
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
      testData: {'products': panelTestProducts},
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
