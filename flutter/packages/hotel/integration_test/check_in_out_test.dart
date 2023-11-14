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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/router.dart' as router;
import 'package:hotel/menu_option_data.dart';
import 'package:hotel/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'room_rental_test.dart';

Future<void> selectCheckInOut(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/checkInOut', 'FinDocListFormCheckIn');
}

Future<void> selectCheckOut(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/checkInOut', 'FinDocListFormCheckOut', '2');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  DateTime today = CustomizableDateTime.current;
  var intlFormat = DateFormat('yyyy-MM-dd');
  String todayStringIntl = intlFormat.format(today);

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets("Test checkin >>>>>", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel reservation Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "products": productsHotel,
      "assets": roomsHotel,
      "users": customers
    });
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.tapByKey(tester, 'refresh');
    await createRoomReservation(tester, roomReservations.sublist(0));
    await selectCheckInOut(tester);
    expect(find.byKey(const Key('id0')), findsNWidgets(1));
    expect(CommonTest.getTextField('status0'), equals('Created'));
    await CommonTest.tapByKey(tester, 'id0');
    expect(CommonTest.getTextField('itemLine0'), contains(todayStringIntl));
    await CommonTest.tapByKey(tester, 'nextStatus0', seconds: 5);
  }, skip: false);

  testWidgets("Test checkout >>>>>", (WidgetTester tester) async {
    // change current time so reservation show in checkout
    CustomizableDateTime.customTime =
        DateTime.now().add(const Duration(days: 1));
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel reservation Checkout Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNWidgets(1));
    expect(CommonTest.getTextField('status0'), equals('Checked In'));
    await CommonTest.tapByKey(tester, 'id0');
    expect(CommonTest.getTextField('itemLine0'), contains(todayStringIntl));
    await CommonTest.tapByKey(tester, 'nextStatus0');
  }, skip: false);

  testWidgets("Test empty checkin and checkout >>>>>",
      (WidgetTester tester) async {
    CustomizableDateTime.customTime =
        DateTime.now().add(const Duration(days: 1));
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel reservation empty checkin/out Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await selectCheckInOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
  }, skip: false);
}
