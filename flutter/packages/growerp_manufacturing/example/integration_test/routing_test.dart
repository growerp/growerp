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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP Routing test', (tester) async {
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
      title: 'Routing test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await RoutingTest.selectRoutings(tester);
    await RoutingTest.addRoutings(tester, [
      Routing(routingName: 'Weld and Assemble'),
    ]);
    await RoutingTest.openRouting(tester, 0);
    await RoutingTest.addRoutingTasks(tester, [
      RoutingTask(
        taskName: 'Cut',
        sequenceNum: 10,
        estimatedWorkTime: Decimal.parse('1.5'),
        workCenterName: 'CNC',
      ),
      RoutingTask(
        taskName: 'Weld',
        sequenceNum: 20,
        estimatedWorkTime: Decimal.parse('2.0'),
        workCenterName: 'Welding',
      ),
      RoutingTask(
        taskName: 'Inspect',
        sequenceNum: 30,
        workCenterName: 'QC',
      ),
    ]);
    await RoutingTest.checkRoutingTasks(tester, [
      RoutingTask(taskName: 'Cut'),
      RoutingTask(taskName: 'Weld'),
      RoutingTask(taskName: 'Inspect'),
    ]);
    await RoutingTest.deleteRoutingTask(tester, 2);
    await RoutingTest.checkRoutingTasks(tester, [
      RoutingTask(taskName: 'Cut'),
      RoutingTask(taskName: 'Weld'),
    ]);
    await CommonTest.tapByKey(tester, 'cancel');
    await RoutingTest.deleteRouting(tester, 0);
    await CommonTest.logout(tester);
  });
}
