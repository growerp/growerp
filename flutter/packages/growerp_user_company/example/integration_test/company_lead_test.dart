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
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectLeads(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, 'dbCompanies', 'CompanyListFormLead', '3');
  }

  testWidgets('''GrowERP company lead test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        UserCompanyLocalizations.localizationsDelegates,
        title: "lead company test", clear: true);
    await CommonTest.createCompanyAndAdmin(tester);
    await selectLeads(tester);
    await CompanyTest.enterCompanyData(tester, leadCompanies.sublist(0, 3));
    await selectLeads(tester);
    await CompanyTest.checkCompany(tester);
    await selectLeads(tester);
    await CompanyTest.enterCompanyData(tester, leadCompanies.sublist(3, 6));
    await selectLeads(tester);
    await CompanyTest.checkCompany(tester);
  }, skip: false);
}
