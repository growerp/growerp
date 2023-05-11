/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hotel/menu_option_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/router.dart' as router;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  DateTime today = CustomizableDateTime.current;
  var intlFormat = DateFormat('yyyy-MM-dd');
  String todayStringIntl = intlFormat.format(today);

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP asset rental sales order test''', (tester) async {
    await CommonTest.startTestApp(tester, router.generateRoute, menuOptions,
        clear: true);

    await CommonTest.createCompanyAndAdmin(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, [categories[0]], check: false);
    await ProductTest.selectProducts(tester);
    await ProductTest.addProducts(tester, [products[2]], check: false);
    await AssetTest.selectAsset(tester);
    await AssetTest.addAssets(tester, [assets[2]], check: false);
    await UserTest.selectCustomers(tester);
    await UserTest.addCustomers(tester, [customers[0]], check: false);
    // rental order test
  });

  testWidgets("Test checkin >>>>>", (WidgetTester tester) async {
    await CommonTest.login(tester);
    if (CommonTest.isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump(const Duration(seconds: 10));
    }
    await tester.tap(find.byKey(const Key('tap/checkInOut')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('FinDocsFormCheckIn')), findsOneWidget);
    expect(find.byKey(const Key('finDocItem')), findsNWidgets(1));
    expect(CommonTest.getTextField('statusId0'), equals('Created'));
    await tester.tap(find.byKey(const Key('ID0')));
    await tester.pump(const Duration(seconds: 10));
    expect(CommonTest.getTextField('itemLine0'), contains(todayStringIntl));
    await tester.tap(find.byKey(const Key('nextStatus')));
    await tester.pump(const Duration(seconds: 10));
  }, skip: false);

  testWidgets("Test checkout >>>>>", (WidgetTester tester) async {
    await CommonTest.login(tester, days: 1);
    if (CommonTest.isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump(const Duration(seconds: 10));
    }
    await tester.tap(find.byKey(const Key('tap/checkInOut')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('FinDocsFormCheckIn')), findsOneWidget);
    if (CommonTest.isPhone()) {
      await tester.tap(find.byTooltip('2'));
    } else {
      await tester.tap(find.byKey(const Key('tapFinDocsFormCheckOut')));
    }
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('FinDocsFormCheckOut')), findsOneWidget);
    // refresh screen
    await tester.drag(
        find.byKey(const Key('listView')), const Offset(0.0, 500.0));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byKey(const Key('finDocItem')), findsNWidgets(1));
    expect(CommonTest.getTextField('statusId0'), equals('Checked In'));
    await tester.tap(find.byKey(const Key('ID0')));
    await tester.pump(const Duration(seconds: 10));
    expect(CommonTest.getTextField('itemLine0'), contains(todayStringIntl));
    await tester.tap(find.byKey(const Key('nextStatus')));
    await tester.pump(const Duration(seconds: 10));
  }, skip: false);

  testWidgets("Test empty checkin and checkout >>>>>",
      (WidgetTester tester) async {
    await CommonTest.login(tester);
    //  username: 'e87@example.org');
    if (CommonTest.isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump(const Duration(seconds: 10));
    }
    await tester.tap(find.byKey(const Key('tap/checkInOut')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('finDocItem')), findsNothing);
    if (CommonTest.isPhone()) {
      await tester.tap(find.byTooltip('2'));
    } else {
      await tester.tap(find.byKey(const Key('tapFinDocsFormCheckOut')));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('finDocItem')), findsNothing);
  }, skip: false);
}
