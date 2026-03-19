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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manufacturing_example/main.dart';

// Component products pre-created so the autocomplete can find them by pseudoId.
final List<Product> componentProducts = [
  Product(
    pseudoId: 'MFG-COMP-001',
    productName: 'Component A',
    productTypeId: 'GoodsSaleShipped',
    price: Decimal.parse('10.00'),
    listPrice: Decimal.parse('12.00'),
  ),
  Product(
    pseudoId: 'MFG-COMP-002',
    productName: 'Component B',
    productTypeId: 'GoodsSaleShipped',
    price: Decimal.parse('5.00'),
    listPrice: Decimal.parse('6.00'),
  ),
];

// Assembly product pre-created for Work Order tests (only).
final Product assemblyProduct = Product(
  pseudoId: 'MFG-ASSY-001',
  productName: 'Assembly Product',
  productTypeId: 'GoodsSaleShipped',
  price: Decimal.parse('100.00'),
  listPrice: Decimal.parse('120.00'),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP BOM test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createManufacturingExampleRouter(),
      manufacturingMenuConfig,
      ManufacturingLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: [
        ...getManufacturingBlocProviders(restClient),
        ...getCatalogBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'BOM test',
      clear: true,
    );
    // Pre-create component products so the autocomplete can find them.
    // The assembly product is created via the BOM dialog.
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"products": componentProducts},
    );
    await BomTest.selectBom(tester);
    await BomTest.createBomWithComponents(
      tester,
      pseudoId: 'MFG-ASSY-001',
      productName: 'Assembly Product',
      components: [
        BomItem(
          componentPseudoId: 'MFG-COMP-001',
          quantity: Decimal.parse('2'),
        ),
        BomItem(
          componentPseudoId: 'MFG-COMP-002',
          quantity: Decimal.parse('3'),
        ),
      ],
    );
    await BomTest.checkBomComponents(tester, [
      BomItem(componentPseudoId: 'MFG-COMP-001'),
      BomItem(componentPseudoId: 'MFG-COMP-002'),
    ]);
    await BomTest.deleteBomComponent(tester, 0);
    await CommonTest.logout(tester);
  });

  testWidgets('GrowERP Work Order test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createManufacturingExampleRouter(),
      manufacturingMenuConfig,
      ManufacturingLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: [
        ...getManufacturingBlocProviders(restClient),
        ...getCatalogBlocProviders(restClient, 'AppAdmin'),
      ],
      title: 'Work Order test',
      clear: true,
    );
    // Pre-create the assembly product for the work order.
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"products": [assemblyProduct]},
    );
    await WorkOrderTest.selectWorkOrders(tester);
    await WorkOrderTest.addWorkOrders(tester, [
      WorkOrder(
        productPseudoId: 'MFG-ASSY-001',
        estimatedQuantity: Decimal.parse('10'),
      ),
    ]);
    await WorkOrderTest.deleteWorkOrder(tester, 0);
    await CommonTest.logout(tester);
  });
}
