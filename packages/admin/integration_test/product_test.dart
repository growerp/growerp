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
import 'package:core/api_repository.dart';
import 'package:core/domains/integration_test.dart';
import 'package:core/services/chat_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP product test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: true); // use data of previous run, when none, same as true
    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, categories.sublist(0, 2),
        check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, products);
    await ProductTest.updateProducts(tester);
    await ProductTest.deleteLastProduct(tester);
    await CommonTest.logout(tester);
  });
}
