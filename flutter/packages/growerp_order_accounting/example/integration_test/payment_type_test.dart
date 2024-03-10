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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:order_accounting_example/main.dart' as router;
import 'package:order_accounting_example/main.dart';
import 'package:growerp_core/test_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  String title = 'PaymentType Test';
  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets(title, (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        OrderAccountingLocalizations.localizationsDelegates,
        title: title,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester);

    await PaymentTypeTest.selectPaymentType(tester);
    await PaymentTypeTest.deleteAllPaymentTypes(tester);
    await PaymentTypeTest.addPaymentTypes(tester, paymentTypes.sublist(0, 2));
    await CommonTest.gotoMainMenu(tester);
    await PaymentTypeTest.selectPaymentType(tester);
    await PaymentTypeTest.addPaymentTypes(tester, paymentTypes.sublist(2, 4));
  });
}