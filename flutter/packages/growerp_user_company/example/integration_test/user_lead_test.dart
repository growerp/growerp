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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectLeads(WidgetTester tester) async {
    await UserTest.selectUsers(tester, '/users', 'UserListLead', '2');
  }

  testWidgets('''GrowERP user lead test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP user-lead test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectLeads(tester);
    await UserTest.addUsers(tester, leads.sublist(0, 3));
    await UserTest.checkUsers(tester);
    await UserTest.updateUsers(tester, leads.sublist(3, 6));
    await UserTest.checkUsers(tester);
    await UserTest.deleteUsers(tester);
    await CommonTest.logout(tester);
  });
}
