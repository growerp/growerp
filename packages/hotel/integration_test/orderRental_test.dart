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

import 'package:core/api_repository.dart';
import 'package:core/domains/common/widgets/observer.dart';
import 'package:core/domains/integration_test.dart';
import 'package:core/services/chat_server.dart';
import 'package:hotel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:core/extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  DateTime today = CustomizableDateTime.current;
  DateTime plus2 = today.add(Duration(days: 2));
  var usFormat = new DateFormat('M/d/yyyy');
  var intlFormat = new DateFormat('yyyy-MM-dd');
  String plus2StringUs = usFormat.format(plus2);
  String todayStringIntl = intlFormat.format(today);
  String plus2StringIntl = intlFormat.format(plus2);

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    Bloc.observer = AppBlocObserver();
  });

  group('Order Rental tests>>>>>', () {
    testWidgets("Prepare>>>>>>", (WidgetTester tester) async {
      await CommonTest.startApp(
          tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()));
      await CommonTest.createCompanyAndAdmin(tester);
      await AssetTest.addAssets(tester, assets);
      String random = CommonTest.getRandom();
      await UserTest.selectCustomers(tester);
      await UserTest.addCustomers(tester, customers.sublist(0, 1));
      await OrderTest.createRentalSalesOrder(tester, rentalSalesOrders);
    }, skip: false);

    testWidgets("check orders for rental data >>>>>",
        (WidgetTester tester) async {
      await CommonTest.startApp(
          tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()));
      await CommonTest.createCompanyAndAdmin(tester);
      await tester.tap(find.byKey(Key('tap/sales')));
      await tester.pump(Duration(seconds: 1));
      expect(find.byKey(Key('FinDocsFormSalesOrder')), findsOneWidget);
      // check list
      for (int x in [0, 1]) {
        expect(CommonTest.getTextField('statusId$x'), equals('Created'));
        await tester.tap(find.byKey(Key('ID$x')));
        await tester.pump(Duration(seconds: 10));
        expect(CommonTest.getTextField('itemLine$x'),
            contains(x == 0 ? '$todayStringIntl' : '$plus2StringIntl'));
      }
    }, skip: false);
    testWidgets("check blocked dates for new reservation>>>>>",
        (WidgetTester tester) async {
      await CommonTest.startApp(
          tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()));
      if (CommonTest.isPhone()) {
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pump(Duration(seconds: 10));
      }
      await tester.tap(find.byKey(Key('tap/sales')));
      await tester.pump(Duration(seconds: 1));
      expect(find.byKey(Key('FinDocsFormSalesOrder')), findsOneWidget);
      await tester.tap(find.byKey(Key('addNew')));
      await tester.pump();
      await tester.tap(find.byKey(Key('product')));
      await tester.pump(Duration(seconds: 5));
      await tester.tap(find.textContaining('productName2').last);
      await tester.pump(Duration(seconds: 1));
      await tester.tap(find.byKey(Key('setDate')));
      await tester.pump(Duration(seconds: 1));
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pump(Duration(seconds: 1));
      await tester.enterText(find.byType(TextField).last, plus2StringUs);
      await tester.pump(Duration(seconds: 1));
      await tester.tap(find.text('OK'));
      await tester.pump(Duration(seconds: 1));
      expect(find.text('Out of range.'), findsOneWidget);
      await tester.tap(find.text('CANCEL'));
      await tester.pump(Duration(seconds: 1));
      await tester.tap(find.byKey(Key('cancel')));
      await tester.pump(Duration(seconds: 1));
    }, skip: false);
  });
}
