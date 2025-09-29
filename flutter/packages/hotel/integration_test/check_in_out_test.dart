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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/router.dart' as router;
import 'package:hotel/main.dart';
import 'package:hotel/views/gantt_form.dart';
import 'package:growerp_models/growerp_models.dart';

import 'room_rental_test.dart';

// Static menuOptions for testing (no localization needed)
List<MenuOption> testMenuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/dashBoardGrey.png",
    selectedImage: "packages/growerp_core/images/dashBoard.png",
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const GanttForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/companyGrey.png",
    selectedImage: "packages/growerp_core/images/company.png",
    title: 'My Hotel',
    route: '/myHotel',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: ShowCompanyDialog(
          Company(role: Role.company),
          key: const Key('CompanyForm'),
          dialog: false,
        ),
        label: 'Company',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const UserList(key: Key('Employee'), role: Role.company),
        label: 'Employees',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const WebsiteDialog(),
        label: 'Website',
        icon: const Icon(Icons.webhook),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/single-bedGrey.png",
    selectedImage: "packages/growerp_core/images/single-bed.png",
    title: 'Rooms',
    route: '/rooms',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const AssetList(),
        label: 'Rooms',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const ProductList(),
        label: 'Room Types',
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/reservationGrey.png",
    selectedImage: "packages/growerp_core/images/reservation.png",
    title: 'Reservations',
    route: '/reservations',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("SalesOrder"),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
        ),
        label: 'Reservations',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
        label: 'Customers',
        icon: const Icon(Icons.school),
      ),
      TabItem(
        form: const FinDocList(
          key: Key('PurchaseOrder'),
          sales: false,
          docType: FinDocType.order,
        ),
        label: 'Purchase Orders',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const CompanyUserList(key: Key('Supplier'), role: Role.supplier),
        label: 'Suppliers',
        icon: const Icon(Icons.business),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/check-in-outGrey.png",
    selectedImage: "packages/growerp_core/images/check-in-out.png",
    title: 'In/Out',
    route: '/checkInOut',
    userGroups: [UserGroup.admin, UserGroup.employee],
    tabItems: [
      TabItem(
        form: const FinDocList(
          key: Key("Check-In"),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
          status: FinDocStatusVal.created,
        ),
        label: 'Check In',
        icon: const Icon(Icons.home),
      ),
      TabItem(
        form: const FinDocList(
          key: Key("Check-Out"),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
          status: FinDocStatusVal.approved,
        ),
        label: 'Check Out',
        icon: const Icon(Icons.home),
      ),
    ],
  ),
  MenuOption(
    image: "packages/growerp_core/images/accountingGrey.png",
    selectedImage: "packages/growerp_core/images/accounting.png",
    title: 'Accounting',
    route: '/accounting',
    userGroups: [UserGroup.admin],
  ),
];

Future<void> selectCheckInOut(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/checkInOut', 'FinDocListCheckIn');
}

Future<void> selectCheckOut(WidgetTester tester) async {
  await CommonTest.selectOption(
    tester,
    '/checkInOut',
    'FinDocListCheckOut',
    '2',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  DateTime today = CustomizableDateTime.current;
  var intlFormat = DateFormat('yyyy-MM-dd');
  String todayStringIntl = intlFormat.format(today);
  String classificationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets("Test checkin >>>>>", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      restClient: restClient,
      title: 'Hotel check in Test',
      tester,
      router.generateRoute,
      testMenuOptions,
      delegates,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
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
    // change current time so reservation show in checkout
    CustomizableDateTime.customTime = DateTime.now().add(
      const Duration(days: 1),
    );
    await CommonTest.startTestApp(
      clear: true,
      restClient: restClient,
      title: 'Hotel Checkout Test',
      tester,
      router.generateRoute,
      testMenuOptions,
      delegates,
      blocProviders: getHotelBlocProviders(restClient, 'AppHotel'),
      classificationId: classificationId,
    );
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNWidgets(1));

    expect(CommonTest.getTextField('status0'), FinDocStatusVal.approved.hotel);
    await CommonTest.tapByKey(tester, 'id0');
    expect(
      CommonTest.getDropdown(
        'statusDropDown',
        classificationId: classificationId,
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
      clear: true,
      restClient: restClient,
      title: 'Hotel reservation empty checkin/out Test',
      tester,
      router.generateRoute,
      testMenuOptions,
      delegates,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await selectCheckInOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
    await selectCheckOut(tester);
    expect(find.byKey(const Key('id0')), findsNothing);
    await selectReservations(tester);
    await OrderTest.checkOrderCompleted(
      tester,
      classificationId: classificationId,
    );
  }, skip: false);
}
