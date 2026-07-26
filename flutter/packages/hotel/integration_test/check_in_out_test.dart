/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/main.dart';
import 'package:growerp_models/growerp_models.dart';

import 'room_rental_test.dart';

Future<void> selectCheckInOut(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/checkInOut', 'CheckIn');
}

Future<void> selectCheckOut(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/checkInOut', 'CheckOut', 'Check Out');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  DateTime today = CustomizableDateTime.current;
  var intlFormat = DateFormat('yyyy-MM-dd');
  String todayStringIntl = intlFormat.format(today);
  String applicationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets("Test checkin >>>>>", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHotelTestRouter(),
      hotelTestMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Hotel check in Test',
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
    await CommonTest.tapByKey(tester, 'refresh');
    await createRoomReservation(tester, roomReservations.sublist(0));
    await selectCheckInOut(tester);
    expect(find.byKey(const Key('id0')), findsNWidgets(1));

    expect(CommonTest.getTextField('status0'), FinDocStatusVal.created.hotel);
    await CommonTest.tapByKey(tester, 'id0');
    expect(CommonTest.getTextField('fromDate0'), contains(todayStringIntl));
    await CommonTest.tapByKey(tester, 'statusDropDown');
    await CommonTest.tapByText(tester, FinDocStatusVal.approved.hotel);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
  }, skip: false);

  testWidgets("Test checkout >>>>>", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    CustomizableDateTime.customTime = DateTime.now().add(
      const Duration(days: 1),
    );
    await CommonTest.startTestApp(
      tester,
      createHotelTestRouter(),
      hotelTestMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, 'AppHotel'),
      applicationId: applicationId,
      clear: false,
      title: 'Hotel Checkout Test',
    );
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNWidgets(1));

    expect(CommonTest.getTextField('status0'), FinDocStatusVal.approved.hotel);
    await CommonTest.tapByKey(tester, 'id0');
    expect(
      CommonTest.getDropdown(
        'statusDropDown',
        applicationId: applicationId,
      ),
      equals(FinDocStatusVal.approved.hotel),
    );
    await CommonTest.tapByKey(tester, 'statusDropDown');
    await CommonTest.tapByText(tester, FinDocStatusVal.completed.hotel);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
  }, skip: false);

  testWidgets("Test empty checkin and checkout >>>>>", (
    WidgetTester tester,
  ) async {
    RestClient restClient = RestClient(await buildDioClient());
    CustomizableDateTime.customTime = DateTime.now().add(
      const Duration(days: 1),
    );
    await CommonTest.startTestApp(
      tester,
      createHotelTestRouter(),
      hotelTestMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: false,
      title: 'Hotel reservation empty checkin/out Test',
    );
    await selectCheckInOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
    await selectReservations(tester);
    await OrderTest.checkOrderCompleted(
      tester,
      applicationId: applicationId,
    );
    await CommonTest.logout(tester);
  }, skip: false);
}
