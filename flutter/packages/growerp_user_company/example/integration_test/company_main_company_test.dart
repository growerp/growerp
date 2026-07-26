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

import 'package:user_company_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/src/company/integration_test/company_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP main company test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createUserCompanyExampleRouter(),
      userCompanyMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      title: "growerp_user_company: main company test",
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    // Navigate to Companies tab - Main Company is the first tab (default)
    await CommonTest.selectOption(
      tester,
      '/companies',
      'CompanyListMain',
      'Main Company', // Tab title for phone bottom navigation
    );
    await CompanyTest.addCompanies(tester, [company]); // modify
    await CommonTest.selectOption(
      tester,
      '/companies',
      'CompanyListMain',
      'Main Company',
    );
    await CompanyTest.checkCompanies(tester);
    await CommonTest.logout(tester);
  });
}
