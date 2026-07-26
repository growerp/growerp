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
import 'package:growerp_order_accounting/src/accounting/integration_test/transaction_test.dart';
import 'package:order_accounting_example/router_builder.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP transaction test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOrderAccountingExampleRouter(),
      orderAccountingMenuConfig,
      OrderAccountingLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      title: "Transaction test",
      clear: true,
    ); // use data from previous run, ifnone same as true

    await CommonTest.createCompanyAndAdmin(tester);
    await TransactionTest.selectTransactions(tester);
    await TransactionTest.addTransactions(tester, transactions.sublist(0, 2));
    await TransactionTest.updateTransactions(
      tester,
      transactions.sublist(2, 4),
    );
    await TransactionTest.postTransactions(tester);
    await TransactionTest.checkTransactionsComplete(tester);
    await CommonTest.logout(tester);
  });
}
