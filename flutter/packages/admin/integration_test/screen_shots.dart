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

import 'package:admin/main.dart';
import 'package:admin/menu_options.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:admin/router.dart' as router;
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets('''Make screenshots''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
        tester, router.generateRoute, menuOptions, delegates,
        restClient: restClient,
        blocProviders: getAdminBlocProviders(restClient, 'AppAdmin'),
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    await binding.takeScreenshot('dashBoard');
    await CompanyTest.selectCompany(tester);
    await CommonTest.takeScreenshot(tester, binding, 'CompanyInfo');
  });
}
