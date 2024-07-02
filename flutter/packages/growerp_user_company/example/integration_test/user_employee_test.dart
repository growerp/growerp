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
import 'package:growerp_models/growerp_models.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectEmployees(WidgetTester tester) async {
    await UserTest.selectUsers(tester, 'dbUsers', 'UserListEmployee', '1');
  }

  testWidgets('''GrowERP user employee test''', (tester) async {
    try {
      RestClient restClient = RestClient(await buildDioClient());
      await CommonTest.startTestApp(tester, generateRoute, menuOptions,
          UserCompanyLocalizations.localizationsDelegates,
          restClient: restClient,
          clear: true,
          title: 'GrowERP user-employee test',
          blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'));
      await CommonTest.createCompanyAndAdmin(tester);
      await selectEmployees(tester);
      await UserTest.addAdministrators(tester, administrators.sublist(0, 3));
      await UserTest.updateAdministrators(tester, administrators.sublist(3, 6));
      await UserTest.deleteAdministrators(tester);
      await selectEmployees(tester);
      await UserTest.addEmployees(tester, employees.sublist(0, 3));
      await UserTest.updateEmployees(tester, employees.sublist(3, 6));
      await UserTest.deleteEmployees(tester);
    } catch (error) {
      await CommonTest.takeScreenShot(
          binding: binding, tester: tester, screenShotName: "Asset_Error");
      rethrow;
    }
  }, skip: false);
}
