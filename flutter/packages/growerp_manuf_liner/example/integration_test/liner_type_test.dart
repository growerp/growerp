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
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'liner_test_app.dart';

final List<LinerType> linerTypeTestData = [
  LinerType(
    linerName: '60 mil HDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.306'),
  ),
  LinerType(
    linerName: '40 mil LLDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.204'),
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('GrowERP LinerType test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createLinerExampleRouter(),
      linerExampleMenuConfig,
      linerExampleDelegates,
      restClient: restClient,
      blocProviders: [
        ...getManufacturingBlocProviders(restClient),
        ...getCatalogBlocProviders(restClient, 'AppAdmin'),
        ...getLinerBlocProviders(restClient),
      ],
      title: 'LinerType test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    // Add two liner types and verify they are displayed.
    await LinerTypeTest.selectLinerTypes(tester);
    await LinerTypeTest.addLinerTypes(tester, linerTypeTestData);

    // Open the first item and verify the dialog opens.
    await LinerTypeTest.openLinerType(tester, 0);
    // Close dialog.
    await CommonTest.tapByKey(tester, 'cancel');

    // Delete the first item.
    await LinerTypeTest.deleteLinerType(tester, 0);

    await CommonTest.logout(tester);
  });
}
