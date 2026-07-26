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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manufacturing_example/main.dart';

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
}
