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

// The housekeeping board driven by the reservation flow: a stay makes the
// room occupied, checking the guest out leaves the room dirty and the
// all-clean button ends the housekeeping round.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_rental/growerp_rental.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hotel/main.dart';
import 'package:hotel/views/housekeeping_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hotel_features_test.dart' show waitForKey;

const housekeepingMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_HOUSEKEEPING_TEST',
  appId: 'hotel',
  name: 'Hotel Housekeeping Test',
  menuItems: [
    MenuItem(
      title: 'Main',
      route: '/',
      widgetName: 'GanttForm',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      title: 'Reservations',
      route: '/reservations',
      widgetName: 'SalesOrder',
      iconName: 'event',
      sequenceNum: 20,
    ),
    MenuItem(
      title: 'Housekeeping',
      route: '/housekeeping',
      widgetName: 'HousekeepingForm',
      iconName: 'cleaning_services',
      sequenceNum: 30,
    ),
  ],
);

GoRouter createHousekeepingRouter() {
  return createStaticAppRouter(
    menuConfig: housekeepingMenuConfig,
    appTitle: 'GrowERP Hotel',
    widgetBuilder: (route) => switch (route) {
      '/housekeeping' => const HousekeepingForm(key: Key('HousekeepingForm')),
      '/reservations' => const FinDocList(
        key: Key('SalesOrder'),
        sales: true,
        docType: FinDocType.order,
        onlyRental: true,
      ),
      _ => const GanttForm(),
    },
    dashboard: const GanttForm(),
    tabWidgetLoader: (widgetName, args) => switch (widgetName) {
      'SalesOrder' => const FinDocList(
        key: Key('SalesOrder'),
        sales: true,
        docType: FinDocType.order,
        onlyRental: true,
      ),
      'HousekeepingForm' => const HousekeepingForm(key: Key('HousekeepingForm')),
      _ => const SizedBox.shrink(),
    },
    additionalRoutes: [
      GoRoute(
        path: '/findoc',
        builder: (context, state) =>
            ShowFinDocDialog(state.extra as FinDoc? ?? FinDoc()),
      ),
    ],
  );
}

Future<void> selectHousekeeping(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/housekeeping', 'HousekeepingForm');
  await waitForKey(tester, 'hkSummary');
}

Future<void> selectReservations(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/reservations', 'SalesOrder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  String applicationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets("housekeeping follows the stay", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHousekeepingRouter(),
      housekeepingMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Hotel Housekeeping Test',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        "products": productsHotel,
        "assets": roomsHotel,
        "users": customers,
      },
    );
    await CommonTest.waitForSnackbarToGo(tester);

    await checkAllRoomsCleanAndFree(tester);
    await createStayForToday(tester);
    await checkRoomOccupied(tester);
    await checkOutMakesRoomDirty(tester);
    await checkAllCleanButton(tester);

    await CommonTest.logout(tester);
  }, skip: false);
}

/// Rooms that were never touched report clean and unoccupied.
Future<void> checkAllRoomsCleanAndFree(WidgetTester tester) async {
  await selectHousekeeping(tester);
  expect(
    CommonTest.getTextField('hkSummary'),
    'Rooms: ${roomsHotel.length}   To clean: 0',
  );
  expect(CommonTest.getTextField('hkRoom0'), 'Room  1'); // the single room
  expect(CommonTest.getTextField('hkOccupied0'), 'no');
  expect(CommonTest.getTextField('hkStatus0'), 'Clean');
}

/// One night in the only Single Room, starting today, and check the guest in.
Future<void> createStayForToday(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.tapByKey(tester, 'refresh', seconds: CommonTest.waitTime);
  await CommonTest.tapByKey(tester, 'addNew');
  await CommonTest.checkWidgetKey(tester, 'ReservationDialog');
  await CommonTest.tapByKey(tester, 'customer');
  await CommonTest.tapByText(tester, customers[0].lastName!);
  await CommonTest.tapByKey(tester, 'product', seconds: CommonTest.waitTime);
  await CommonTest.tapByText(tester, 'Single Room');
  await CommonTest.drag(tester);
  await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);

  // check in: the room is only assigned to the stay when it is approved
  await setOrderStatus(tester, FinDocStatusVal.approved);
}

Future<void> setOrderStatus(
  WidgetTester tester,
  FinDocStatusVal status,
) async {
  await selectReservations(tester);
  await CommonTest.tapByKey(tester, 'id0');
  await CommonTest.tapByKey(tester, 'statusDropDown');
  await CommonTest.tapByText(tester, status.hotel);
  await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
  await CommonTest.waitForSnackbarToGo(tester);
}

/// A stay covering today makes the room occupied; it is not dirty yet.
Future<void> checkRoomOccupied(WidgetTester tester) async {
  await selectHousekeeping(tester);
  expect(CommonTest.getTextField('hkOccupied0'), 'yes');
  expect(CommonTest.getTextField('hkStatus0'), 'Clean');
}

/// Checking the guest out hands the room to housekeeping.
Future<void> checkOutMakesRoomDirty(WidgetTester tester) async {
  await setOrderStatus(tester, FinDocStatusVal.completed);
  await selectHousekeeping(tester);
  expect(CommonTest.getTextField('hkStatus0'), 'Dirty');
  expect(
    CommonTest.getTextField('hkSummary'),
    'Rooms: ${roomsHotel.length}   To clean: 1',
  );
}

/// End of the round: one button puts every room back to clean.
Future<void> checkAllCleanButton(WidgetTester tester) async {
  await CommonTest.tapByKey(tester, 'allClean', seconds: CommonTest.waitTime);
  expect(CommonTest.getTextField('hkStatus0'), 'Clean');
  expect(
    CommonTest.getTextField('hkSummary'),
    'Rooms: ${roomsHotel.length}   To clean: 0',
  );

  // and it stuck in the backend, not just in the list on screen
  await selectReservations(tester);
  await selectHousekeeping(tester);
  expect(CommonTest.getTextField('hkSummary'), contains('To clean: 0'));
}
