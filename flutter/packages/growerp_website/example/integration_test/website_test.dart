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
import 'package:integration_test/integration_test.dart';
import 'package:website_example/main.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectWebsite(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbWebsite', 'WebsiteForm');
  }

  testWidgets('''GrowERP website test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        WebsiteLocalizations.localizationsDelegates,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      // related categories also created
      "products": products.sublist(0, 2),
    });

    await selectWebsite(tester);
    await WebsiteTest.updateWebsite(tester);
  });
}
