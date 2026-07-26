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

final List<Product> woProducts = [
  Product(
    pseudoId: 'MFG-ASSY-001',
    productName: 'Assembly Product',
    productTypeId: 'GoodsSaleShipped',
    price: Decimal.parse('100.00'),
    listPrice: Decimal.parse('120.00'),
  ),
  Product(
    pseudoId: 'MFG-COMP-001',
    productName: 'Component A',
    productTypeId: 'GoodsSaleShipped',
    price: Decimal.parse('10.00'),
    listPrice: Decimal.parse('12.00'),
  ),
];

final List<BomItem> woBomItems = [
  BomItem(
    productId: 'MFG-ASSY-001',
    toProductId: 'MFG-COMP-001',
    quantity: Decimal.parse('2'),
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
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
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"products": woProducts, "bomItems": woBomItems},
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
