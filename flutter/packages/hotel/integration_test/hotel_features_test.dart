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

// Covers the hotel-specific features added on top of the reservation flow:
// seasonal (date-banded) room rates, the housekeeping board and the
// occupancy/ADR/RevPAR statistics screen.
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
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/main.dart';
import 'package:hotel/views/housekeeping_form.dart';
import 'package:growerp_rental/growerp_rental.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hotelFeatureMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_FEATURE_TEST',
  appId: 'hotel',
  name: 'Hotel Feature Test',
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
      title: 'Housekeeping',
      route: '/housekeeping',
      widgetName: 'HousekeepingForm',
      iconName: 'cleaning_services',
      sequenceNum: 30,
    ),
    MenuItem(
      title: 'Statistics',
      route: '/statistics',
      widgetName: 'StatisticsForm',
      iconName: 'hotel',
      sequenceNum: 40,
    ),
  ],
);

GoRouter createHotelFeatureRouter() {
  return createStaticAppRouter(
    menuConfig: hotelFeatureMenuConfig,
    appTitle: 'GrowERP Hotel',
    widgetBuilder: (route) => switch (route) {
      '/housekeeping' => const HousekeepingForm(key: Key('HousekeepingForm')),
      '/statistics' => const StatisticsForm(key: Key('StatisticsForm')),
      _ => const GanttForm(),
    },
    dashboard: const GanttForm(),
    tabWidgetLoader: (widgetName, args) => switch (widgetName) {
      'AssetList' => const AssetList(key: Key('AssetList')),
      'ProductList' => const ProductList(key: Key('ProductList')),
      'RentalRateForm' => const RentalRateForm(key: Key('RentalRateForm')),
      'HousekeepingForm' => const HousekeepingForm(key: Key('HousekeepingForm')),
      'StatisticsForm' => const StatisticsForm(key: Key('StatisticsForm')),
      _ => const SizedBox.shrink(),
    },
  );
}

/// Pump until [key] is on screen. The hotel screens load their data over
/// REST after the route settles, so pumpAndSettle alone can return while the
/// screen is still showing its loading indicator.
Future<void> waitForKey(WidgetTester tester, String key) async {
  for (int i = 0; i < 40 && !tester.any(find.byKey(Key(key))); i++) {
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
  }
  expect(
    find.byKey(Key(key)),
    findsWidgets,
    reason: 'screen did not finish loading: no widget with key "$key"',
  );
}

Future<void> selectRates(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/rooms', 'RentalRateForm', 'Rates');
  await waitForKey(tester, 'rateSummary');
}

Future<void> selectHousekeeping(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/housekeeping', 'HousekeepingForm');
  await waitForKey(tester, 'hkSummary');
}

Future<void> selectStatistics(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(tester, '/statistics', 'StatisticsForm');
  await waitForKey(tester, 'totalRooms');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  String applicationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets("hotel rates, housekeeping and statistics", (
    WidgetTester tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHotelFeatureRouter(),
      hotelFeatureMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Hotel Features Test',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"assets": roomsHotel},
    );
    await CommonTest.waitForSnackbarToGo(tester);

    await checkSeasonalRate(tester);
    await checkTouristTax(tester, restClient);
    await checkHousekeeping(tester);
    await checkStatistics(tester);

    await CommonTest.logout(tester);
  }, skip: false);
}

/// Add a seasonal rate band for a room type and confirm it is listed and
/// can be removed again.
Future<void> checkSeasonalRate(WidgetTester tester) async {
  await selectRates(tester);
  await CommonTest.checkWidgetKey(tester, 'RentalRateForm');
  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 0');

  final from = CustomizableDateTime.current.add(const Duration(days: 40));
  final thru = from.add(const Duration(days: 3));
  final rate = Decimal.parse('275');

  await CommonTest.tapByKey(tester, 'addNew');
  await CommonTest.checkWidgetKey(tester, 'RentalRateDialog');
  await CommonTest.enterDate(tester, 'rateFromDate', from, usDate: true);
  await CommonTest.enterDate(tester, 'rateThruDate', thru, usDate: true);
  await CommonTest.enterText(tester, 'rate', rate.toString());
  await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);

  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 1');
  expect(
    CommonTest.getTextField('rateFrom0'),
    DateFormat('yyyy-MM-dd').format(from),
  );
  expect(CommonTest.getTextField('ratePrice0'), rate.toString());

  // the band must survive a reload from the backend
  await selectStatistics(tester);
  await selectRates(tester);
  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 1');

  // and be removable
  await CommonTest.tapByKey(tester, 'rateDelete0', seconds: CommonTest.waitTime);
  expect(CommonTest.getTextField('rateSummary'), 'Seasonal rates: 0');
}

/// The lodging tax set on the rates screen must show up in the price of a
/// stay: tax = nights x rate, on top of the room charge.
Future<void> checkTouristTax(
  WidgetTester tester,
  RestClient restClient,
) async {
  await selectRates(tester);
  await CommonTest.enterText(tester, 'touristTaxPerNight', '3.50');
  await CommonTest.tapByKey(
    tester,
    'saveTouristTax',
    seconds: CommonTest.waitTime,
  );

  final products = await restClient.getProduct(
    limit: 1,
    isForDropDown: true,
    applicationId: 'AppHotel',
  );
  final productId = products.products.first.productId;
  final quote = await restClient.getRentalQuote(
    productId: productId,
    fromDate: DateFormat(
      'yyyy-MM-dd',
    ).format(CustomizableDateTime.current.add(const Duration(days: 60))),
    nights: 4,
  );
  expect(quote.nightlyRates.length, 4);
  expect(quote.touristTax, Decimal.parse('14.0')); // 4 nights x 3.50
  expect(quote.grandTotal, quote.roomTotal! + quote.touristTax!);

  // leave the tenant without a tax so the other hotel tests are unaffected
  // (still on the rates screen: the quote above went straight to REST)
  await CommonTest.enterText(tester, 'touristTaxPerNight', '0');
  await CommonTest.tapByKey(
    tester,
    'saveTouristTax',
    seconds: CommonTest.waitTime,
  );
}

/// Flip a room from Clean to Dirty and confirm the change is persisted.
Future<void> checkHousekeeping(WidgetTester tester) async {
  await selectHousekeeping(tester);
  await CommonTest.checkWidgetKey(tester, 'HousekeepingForm');
  // rooms were seeded by createCompanyAndAdmin
  expect(CommonTest.getTextField('hkSummary'), contains('To clean: 0'));
  expect(CommonTest.getTextField('hkStatus0'), 'Clean');
  expect(CommonTest.getTextField('hkOccupied0'), 'no');

  await CommonTest.tapByKey(tester, 'hkToggle0', seconds: CommonTest.waitTime);
  expect(CommonTest.getTextField('hkStatus0'), 'Dirty');

  // reload: the status came from the backend, not just local state
  await selectStatistics(tester);
  await selectHousekeeping(tester);
  expect(CommonTest.getTextField('hkStatus0'), 'Dirty');
  expect(CommonTest.getTextField('hkSummary'), contains('To clean: 1'));

  // put it back so a rerun starts clean
  await CommonTest.tapByKey(tester, 'hkToggle0', seconds: CommonTest.waitTime);
  expect(CommonTest.getTextField('hkStatus0'), 'Clean');
}

/// The statistics screen reports the seeded rooms; with no reservations in
/// the period occupancy and the derived rates are zero.
Future<void> checkStatistics(WidgetTester tester) async {
  await selectStatistics(tester);
  await CommonTest.checkWidgetKey(tester, 'StatisticsForm');
  expect(CommonTest.getTextField('totalRooms'), roomsHotel.length.toString());
  expect(CommonTest.getTextField('occupancyPercent'), '0%');
  expect(CommonTest.getTextField('adr'), '0');
  expect(CommonTest.getTextField('revPar'), '0');
}
