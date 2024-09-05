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
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hotel/menu_option_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hotel/router.dart' as router;
import 'package:hotel/main.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> selectRoomTypes(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'ProductList', '2');
}

Future<void> selectRooms(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'AssetList');
}

Future<void> selectUserCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'UserListCustomer', '2');
}

Future<void> selectCompanyCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'CompanyListCustomer', '3');
}

Future<void> selectReservations(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'FinDocListSalesOrder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  String classificationId = 'AppHotel';
/*
  DateTime today = CustomizableDateTime.current;
  DateTime plus2 = today.add(const Duration(days: 2));
  var usFormat = DateFormat('M/d/yyyy');
  var intlFormat = DateFormat('yyyy-MM-dd');
  String plus2StringUs = usFormat.format(plus2);
  String todayStringIntl = intlFormat.format(today);
  String plus2StringIntl = intlFormat.format(plus2);
*/
  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    await Hive.initFlutter();
  });

  testWidgets("Test room types", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel Room type Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectRoomTypes(tester);
    await ProductTest.addProducts(tester, productsHotel.sublist(0, 1),
        classificationId: "AppHotel"); // room types
  }, skip: false);

  testWidgets("test rooms", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel Room Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await CommonTest.createCompanyAndAdmin(tester,
        testData: {"products": productsHotel});
    await selectRooms(tester);
    await AssetTest.addAssets(tester, roomsHotel.sublist(0, 4),
        classificationId: "AppHotel"); // actual rooms
  }, skip: false);

  testWidgets("test customer company", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel customer,company Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectCompanyCustomers(tester);
    await CompanyTest.enterCompanyData(tester, customerCompanies);
  }, skip: false);

  testWidgets("test customer contact", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel customer,contacts Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectUserCustomers(tester);
    await UserTest.addCustomers(tester, customers);
  }, skip: false);
}
