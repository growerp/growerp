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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:order_accounting_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP cash book category test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOrderAccountingExampleRouter(),
      orderAccountingMenuConfig,
      OrderAccountingLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      title: "Cash book category test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await CashBookCategoryTest.selectCategories(tester);
    await CashBookCategoryTest.checkDefaults(tester);
    await CashBookCategoryTest.addCategory(tester, 'Coworking desk');
    await CashBookCategoryTest.rename(
      tester,
      'Coworking desk',
      'Coworking space',
    );
    await CashBookCategoryTest.switchOff(
      tester,
      CashBookCategoryTest.defaultExpense,
    );
    // the cash book only offers the categories which are in use
    await CashBookCategoryTest.checkCashBookOffers(
      tester,
      present: ['Coworking space'],
      absent: [
        CashBookCategoryTest.defaultExpense,
        CashBookCategoryTest.unusedExpense,
      ],
    );
    await CashBookCategoryTest.selectCategories(tester);
    await CashBookCategoryTest.switchOn(
      tester,
      CashBookCategoryTest.defaultExpense,
    );
    await CommonTest.logout(tester);
  });
}
