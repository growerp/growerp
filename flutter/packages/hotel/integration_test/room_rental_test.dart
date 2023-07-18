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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:hotel/menu_option_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:hotel/router.dart' as router;
import 'package:hotel/main.dart';

Future<void> selectRoomTypes(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'ProductListForm', '2');
}

Future<void> selectRooms(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'AssetListForm');
}

Future<void> selectUserCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'UserListFormCustomer', '2');
}

Future<void> selectCompanyCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'CompanyListFormCustomer', '3');
}

Future<void> selectReservations(WidgetTester tester) async {
  await CommonTest.selectOption(
      tester, '/reservations', 'FinDocListFormSalesOrder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
  });

  testWidgets("Test room types", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel Room type Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectRoomTypes(tester);
    await ProductTest.addProducts(tester, productsHotel.sublist(0, 1),
        classificationId: "AppHotel"); // room types
  }, skip: false);

  testWidgets("test rooms", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel Room Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await CommonTest.createCompanyAndAdmin(tester,
        testData: {"products": productsHotel});
    await selectRooms(tester);
    await AssetTest.addAssets(tester, roomsHotel.sublist(0, 4),
        classificationId: "AppHotel"); // actual rooms
  }, skip: false);

  testWidgets("test customer company", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel customer,company Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectCompanyCustomers(tester);
    await CompanyTest.enterCompanyData(tester, customerCompanies);
  }, skip: false);

  testWidgets("test customer contact", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel customer,contacts Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectUserCustomers(tester);
    await UserTest.addCustomers(tester, customers);
  }, skip: false);

  testWidgets("test room reservation", (WidgetTester tester) async {
    await CommonTest.startTestApp(
      clear: false,
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
    await createRoomReservation(tester, roomReservations);
    await selectReservations(tester);
    await OrderTest.checkRentalSalesOrder(tester);
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveSalesOrder(tester, classificationId: 'AppHotel');
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await CommonTest.gotoMainMenu(tester);
    await selectReservations(tester);
    await CommonTest.tapByKey(tester, 'nextStatus0',
        seconds: 5); // to completed
    await OrderTest.checkOrderCompleted(tester, classificationId: 'AppHotel');
  }, skip: false);
}

Future<void> createRoomReservation(
    WidgetTester tester, List<FinDoc> finDocs) async {
  SaveTest test = await PersistFunctions.getTest();
  List<FinDoc> newOrders = [];
  var usFormat = DateFormat('M/d/yyyy');
  for (FinDoc finDoc in finDocs) {
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.tapByKey(tester, 'customer');
    await CommonTest.tapByText(tester, finDoc.otherUser!.company!.name!);
    await CommonTest.tapByKey(tester, 'product', seconds: 5);
    await CommonTest.tapByText(tester, finDoc.items[0].description!);
    await CommonTest.tapByKey(tester, 'setDate');
    await CommonTest.tapByTooltip(tester, 'Switch to input');
    await tester.enterText(find.byType(TextField).last,
        usFormat.format(finDoc.items[0].rentalFromDate!));
    await tester.pump();
    await CommonTest.tapByText(tester, 'OK');
    DateTime textField = DateTime.parse(CommonTest.getTextField('date'));
    expect(usFormat.format(textField),
        usFormat.format(finDoc.items[0].rentalFromDate!));
    // nbr of days
    await CommonTest.enterText(
        tester, 'quantity', finDoc.items[0].quantity.toString());
    await CommonTest.enterText(
        tester, 'nbrOfRooms', finDoc.items.length.toString());
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'update', seconds: 5);
    // get productId's from reservations
    await selectReservations(tester);
    await CommonTest.tapByKey(tester, 'id0'); // added at the top
    List<FinDocItem> newItems = List.of(finDoc.items);
    for (int index = 0; index < finDoc.items.length; index++) {
      var productId = CommonTest.getTextField('itemLine$index').split(' ')[1];
      FinDocItem newItem = finDoc.items[index].copyWith(productId: productId);
      newItems[index] = newItem;
    }
    await CommonTest.tapByKey(tester, 'id0'); // close again
    newOrders.add(finDoc.copyWith(
        orderId: CommonTest.getTextField('id0'), items: newItems));
  }
  await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
}
