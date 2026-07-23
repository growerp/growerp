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

// Room pricing: seasonal (date-banded) rates and the tourist tax. Checks the
// rates screen, that the bands are applied per night by the quote service and
// that the tax is charged on a reservation as its own order line.
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_rental/growerp_rental.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hotel_features_test.dart' show waitForKey;

const hotelRateMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_RATE_TEST',
  appId: 'hotel',
  name: 'Hotel Rate Test',
  menuItems: [
    MenuItem(
      title: 'Main',
      route: '/',
      widgetName: 'GanttForm',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      title: 'Rooms',
      route: '/rooms',
      iconName: 'bed',
      sequenceNum: 20,
      children: [
        MenuItem(
          title: 'Rooms',
          widgetName: 'AssetList',
          iconName: 'home',
          sequenceNum: 10,
        ),
        MenuItem(
          title: 'Room Types',
          widgetName: 'ProductList',
          iconName: 'home',
          sequenceNum: 20,
        ),
        MenuItem(
          title: 'Rates',
          widgetName: 'RentalRateForm',
          iconName: 'price_change',
          sequenceNum: 30,
        ),
      ],
    ),
    MenuItem(
      title: 'Reservations',
      route: '/reservations',
      iconName: 'event',
      sequenceNum: 30,
      children: [
        MenuItem(
          title: 'Reservations',
          widgetName: 'SalesOrder',
          iconName: 'home',
          sequenceNum: 10,
        ),
        MenuItem(
          title: 'Customers',
          widgetName: 'CompanyListCustomer',
          iconName: 'school',
          sequenceNum: 20,
        ),
      ],
    ),
  ],
);

GoRouter createHotelRateRouter() {
  return createStaticAppRouter(
    menuConfig: hotelRateMenuConfig,
    appTitle: 'GrowERP Hotel',
    widgetBuilder: (route) => const GanttForm(),
    dashboard: const GanttForm(),
    tabWidgetLoader: (widgetName, args) => switch (widgetName) {
      'AssetList' => const AssetList(key: Key('AssetList')),
      'ProductList' => const ProductList(key: Key('ProductList')),
      'RentalRateForm' => const RentalRateForm(key: Key('RentalRateForm')),
      'SalesOrder' => const FinDocList(
        key: Key('SalesOrder'),
        sales: true,
        docType: FinDocType.order,
        onlyRental: true,
      ),
      'CompanyListCustomer' => const CompanyUserList(
        key: Key('CompanyListCustomer'),
        role: Role.customer,
      ),
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

final dateFormat = DateFormat('yyyy-MM-dd');

/// day [offset] from today, used for both the rate bands and the stays
DateTime day(int offset) =>
    CustomizableDateTime.current.add(Duration(days: offset));

Future<void> selectRates(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/rooms', 'RentalRateForm', 'Rates');
  await waitForKey(tester, 'rateSummary');
}

Future<void> selectRoomTypes(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/rooms', 'ProductList', 'Room Types');
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

  testWidgets("seasonal room rates and tourist tax", (
    WidgetTester tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHotelRateRouter(),
      hotelRateMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Hotel Room Rate Test',
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

    await checkSeasonalBands(tester);
    await checkTouristTaxSetting(tester);
    await checkQuote(restClient);
    await checkReservationPricing(tester);

    await CommonTest.logout(tester);
  }, skip: false);
}

/// Two adjacent rate bands on the Single Room: they are listed in date order
/// and survive a reload from the backend.
Future<void> checkSeasonalBands(WidgetTester tester) async {
  await selectRates(tester);
  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 0');

  await addBand(tester, day(30), day(33), '275');
  await addBand(tester, day(33), day(35), '150');

  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 2');
  expect(CommonTest.getTextField('rateProduct0'), 'Single Room');
  expect(CommonTest.getTextField('rateFrom0'), dateFormat.format(day(30)));
  expect(CommonTest.getTextField('ratePrice0'), '275');
  expect(CommonTest.getTextField('rateProduct1'), 'Single Room');
  expect(CommonTest.getTextField('rateFrom1'), dateFormat.format(day(33)));
  expect(CommonTest.getTextField('ratePrice1'), '150');

  // the bands must come back from the backend, not just local state
  await selectRoomTypes(tester);
  await selectRates(tester);
  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 2');
}

Future<void> addBand(
  WidgetTester tester,
  DateTime from,
  DateTime thru,
  String rate,
) async {
  await CommonTest.tapByKey(tester, 'addNew');
  await CommonTest.checkWidgetKey(tester, 'RentalRateDialog');
  await CommonTest.enterDropDown(tester, 'rentalProductType', 'Single Room');
  await CommonTest.enterDate(tester, 'rateFromDate', from, usDate: true);
  await CommonTest.enterDate(tester, 'rateThruDate', thru, usDate: true);
  await CommonTest.enterText(tester, 'rate', rate);
  await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
}

/// The lodging tax is a per tenant setting: it must still be there, and
/// parseable, after the rates screen has re-read it from the backend.
Future<void> checkTouristTaxSetting(WidgetTester tester) async {
  await CommonTest.enterText(tester, 'touristTaxPerNight', '3.50');
  await CommonTest.tapByKey(
    tester,
    'saveTouristTax',
    seconds: CommonTest.waitTime,
  );
  await CommonTest.waitForSnackbarToGo(tester);

  await selectRoomTypes(tester);
  await selectRates(tester);
  expect(
    await CommonTest.doesExistKey(tester, 'rateError'),
    false,
    reason: 'rates screen failed to load the system settings',
  );
  expect(
    Decimal.parse(CommonTest.getTextFormField('touristTaxPerNight')),
    Decimal.parse('3.50'),
  );
}

/// A stay straddling both bands: each night is priced by the band covering
/// it, the thru date is exclusive and nights outside every band fall back to
/// the room type price (50). The tax is per room per night.
Future<void> checkQuote(RestClient restClient) async {
  final products = await restClient.getProduct(
    limit: 100,
    isForDropDown: true,
    applicationId: 'AppHotel',
  );
  final productId = products.products
      .firstWhere((p) => p.productName == 'Single Room')
      .productId;

  final quote = await restClient.getRentalQuote(
    productId: productId,
    fromDate: dateFormat.format(day(29)),
    nights: 7,
  );
  final expected = ['50', '275', '275', '275', '150', '150', '50'];
  expect(quote.nightlyRates.length, 7);
  for (int i = 0; i < expected.length; i++) {
    expect(
      quote.nightlyRates[i].date,
      dateFormat.format(day(29 + i)),
      reason: 'night $i has the wrong date',
    );
    expect(
      quote.nightlyRates[i].price,
      Decimal.parse(expected[i]),
      reason: 'night ${quote.nightlyRates[i].date} has the wrong rate',
    );
  }
  expect(quote.roomTotal, Decimal.parse('1225')); // 50+3x275+2x150+50
  expect(quote.touristTax, Decimal.parse('24.50')); // 7 nights x 3.50
  expect(quote.grandTotal, Decimal.parse('1249.50'));
  expect(quote.averageNightlyRate, Decimal.parse('175'));

  // room charge and tax both scale with the number of rooms
  final twoRooms = await restClient.getRentalQuote(
    productId: productId,
    fromDate: dateFormat.format(day(29)),
    nights: 7,
    quantity: 2,
  );
  expect(twoRooms.roomTotal, Decimal.parse('2450'));
  expect(twoRooms.touristTax, Decimal.parse('49.00'));
  expect(twoRooms.grandTotal, Decimal.parse('2499.00'));
}

/// Booking three nights inside the high season band: the dialog shows the
/// banded room charge with the tax on top and stores the tax as its own line.
Future<void> checkReservationPricing(WidgetTester tester) async {
  // reservations are created from the gantt chart on the main screen
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.tapByKey(tester, 'refresh', seconds: CommonTest.waitTime);
  await CommonTest.tapByKey(tester, 'addNew');
  await CommonTest.checkWidgetKey(tester, 'ReservationDialog');

  await CommonTest.tapByKey(tester, 'customer');
  await CommonTest.tapByText(tester, customers[0].lastName!);
  await CommonTest.tapByKey(tester, 'product', seconds: CommonTest.waitTime);
  await CommonTest.tapByText(tester, 'Single Room');
  await CommonTest.enterDate(tester, 'setDate', day(30), usDate: true);
  // 'quantity' is the number of nights, the number of rooms is always 1
  await CommonTest.enterText(tester, 'quantity', '3');
  await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));

  expect(
    Decimal.parse(CommonTest.getTextFormField('price')),
    Decimal.parse('275'),
  );
  expect(
    Decimal.parse(CommonTest.getTextField('roomTotal')),
    Decimal.parse('825'), // 3 x 275
  );
  expect(
    Decimal.parse(CommonTest.getTextField('touristTax')),
    Decimal.parse('10.50'), // 3 x 3.50
  );
  expect(
    Decimal.parse(CommonTest.getTextField('grandTotal')),
    Decimal.parse('835.50'),
  );

  await CommonTest.drag(tester);
  await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);

  await selectReservations(tester);
  await CommonTest.tapByKey(tester, 'id0');
  expect(CommonTest.getTextField('itemDescription0'), 'Single Room');
  expect(CommonTest.getTextField('itemDescription1'), 'Tourist tax');
  // the item amounts are only shown on a wide screen, formatted as currency
  if (await CommonTest.doesExistKey(tester, 'itemPrice1')) {
    expect(CommonTest.getTextField('itemPrice0'), contains('275.00'));
    expect(CommonTest.getTextField('itemPrice1'), contains('10.50'));
  }
  await CommonTest.tapByKey(tester, 'cancel');
}
