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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:catalog_example/main.dart';
import 'package:growerp_core/test_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets('''GrowERP category test''', (tester) async {
    try {
      RestClient restClient = RestClient(await buildDioClient());
      await CommonTest.startTestApp(tester, generateRoute, menuOptions,
          CatalogLocalizations.localizationsDelegates,
          restClient: restClient,
          blocProviders: getCatalogBlocProviders(restClient, 'AppAdmin'),
          title: "Category test",
          clear: true); // use data from previous run, ifnone same as true
      await CommonTest.createCompanyAndAdmin(tester);
      await CategoryTest.selectCategories(tester);
      await CategoryTest.addCategories(tester, categories);
      await CategoryTest.updateCategories(tester);
      await CategoryTest.deleteLastCategory(tester);
    } catch (error) {
      await CommonTest.takeScreenShot(
          binding: binding, tester: tester, screenShotName: "Category_Error");
      print("==========test failed: $error");
    }
  });
}
