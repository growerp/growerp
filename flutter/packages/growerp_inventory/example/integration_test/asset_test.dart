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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:inventory_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP asset test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createInventoryExampleRouter(),
      inventoryMenuConfig,
      InventoryLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getInventoryBlocProviders(restClient, "AppAdmin"),
      title: "Asset test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    // Navigate to assets
    await CommonTest.selectOption(tester, '/assets', 'AssetList');
    await CommonTest.logout(tester);
  });
}
