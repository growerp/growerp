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
import 'package:hotel/menu_option_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
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

  testWidgets("test room reservation", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      clear: true,
      title: 'Hotel reservation Test',
      tester,
      router.generateRoute,
      menuOptions,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
    );
    await CommonTest.createCompanyAndAdmin(tester, testData: {
      "assets": roomsHotel, // will also add products
      "users": customers
    });
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.tapByKey(tester, 'refresh');
    await createRoomReservation(tester, roomReservations);
    await selectReservations(tester);
    await FinDocTest.checkFinDocDetail(tester, FinDocType.order,
        rental: true, classificationId: 'AppHotel');
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveOrders(tester, classificationId: classificationId);
    await InvoiceTest.selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await CommonTest.gotoMainMenu(tester);
    await selectReservations(tester);
    await OrderTest.completeOrders(tester,
        classificationId: classificationId); // to completed
    await OrderTest.checkOrderCompleted(tester,
        classificationId: classificationId);
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
    await CommonTest.tapByText(tester, finDoc.otherUser!.lastName!);
    await CommonTest.tapByKey(tester, 'product', seconds: CommonTest.waitTime);
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
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    // get productId's from reservations
    await selectReservations(tester);
    await CommonTest.tapByKey(tester, 'id0'); // added at the top
    List<FinDocItem> newItems = List.of(finDoc.items);
    for (int index = 0; index < finDoc.items.length; index++) {
      var productId = CommonTest.getTextField('itemProductId$index');
      FinDocItem newItem =
          finDoc.items[index].copyWith(product: Product(pseudoId: productId));
      newItems[index] = newItem;
    }
    await CommonTest.tapByKey(tester, 'cancel'); // close again
    newOrders.add(finDoc.copyWith(
        orderId: CommonTest.getTextField('id0'),
        pseudoId: CommonTest.getTextField('id0'),
        items: newItems));
  }
  await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
}
