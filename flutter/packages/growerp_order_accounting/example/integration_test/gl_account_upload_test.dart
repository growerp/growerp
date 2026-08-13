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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_order_accounting/src/accounting/integration_test/gl_account_test.dart';
import 'package:order_accounting_example/router_builder.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GlAccount initial upload test''', (tester) async {
    // the initial upload replaces the whole ledger, so it needs its own
    // company: a new tenant starts without any posting.
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createOrderAccountingExampleRouter(),
      orderAccountingMenuConfig,
      OrderAccountingLocalizations.localizationsDelegates,
      title: 'GlAccount initial upload test',
      restClient: restClient,
      blocProviders: getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // debit positive, credit negative, summing to zero over the file
    const balances = {'11100': '1000', '11110': '-1000'};

    await GlAccountTest.selectLedgerAccounts(tester);
    // nothing posted yet, so the upload is on offer
    expect(find.byKey(const Key('upDownload')), findsOneWidget);
    await GlAccountTest.initialUpload(
      tester,
      periodYear: '2023',
      balances: balances,
    );
    await GlAccountTest.checkPostedBalances(tester, balances);
    // the initial balance itself does not block a correction of the upload
    expect(find.byKey(const Key('upDownload')), findsOneWidget);
    await CommonTest.logout(tester);
  });
}
