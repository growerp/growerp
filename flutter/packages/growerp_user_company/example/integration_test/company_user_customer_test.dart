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
import 'package:growerp_user_company/src/company_user/integration_test/company_user_test.dart';
import 'package:growerp_user_company/src/company/integration_test/company_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectCustomers(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/companiesUsers',
      'CompanyUserListCustomer',
      'Customer\nComp & Users', // Tab title for phone bottom navigation
    );
  }

  var title = 'GrowERP user/company customer test';

  testWidgets(title, (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createUserCompanyExampleRouter(),
      userCompanyMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      title: title,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    await selectCustomers(tester);
    await CompanyUserTest.addUsers(tester, customers.sublist(0, 1));
    await CompanyTest.addCompanies(tester, customerCompanies.sublist(0, 2));
    await CompanyUserTest.checkCompaniesUsers(tester);
    await CompanyUserTest.updateUsers(tester, customers.sublist(0, 2));
    await CompanyUserTest.updateCompanies(tester, customerCompanies);
    await CompanyUserTest.checkCompaniesUsers(tester);
    await CommonTest.logout(tester);
  }, skip: false);
}
