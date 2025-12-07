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

import 'package:user_company_example/main.dart';
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
      'companiesUsers',
      'CompanyUserListCustomer',
      '2',
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
    await CompanyUserTest.addUsers(tester, customers.sublist(0, 2));
    await CompanyTest.addCompanies(tester, customerCompanies);
    await CompanyUserTest.checkCompaniesUsers(tester);
    await CompanyUserTest.updateUsers(tester, customers);
    await CompanyUserTest.updateCompanies(tester, customerCompanies);
    await CompanyUserTest.checkCompaniesUsers(tester);
    await CommonTest.logout(tester);
  }, skip: false);
}
