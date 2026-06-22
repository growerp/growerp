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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/fin_doc_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/order_test.dart';
import 'package:growerp_order_accounting/src/findoc/integration_test/invoice_test.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hotel/main.dart';
import 'package:hotel/views/gantt_form.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hotelTestMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_TEST',
  appId: 'hotel',
  name: 'Hotel Test',
  menuItems: [
    MenuItem(
      title: 'Main',
      route: '/',
      widgetName: 'GanttForm',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      title: 'My Hotel',
      route: '/myHotel',
      iconName: 'business',
      sequenceNum: 20,
      children: [
        MenuItem(
          title: 'Company',
          widgetName: 'CompanyForm',
          iconName: 'home',
          sequenceNum: 10,
        ),
        MenuItem(
          title: 'Employees',
          widgetName: 'UserListEmployee',
          iconName: 'school',
          sequenceNum: 20,
        ),
        MenuItem(
          title: 'Website',
          widgetName: 'WebsiteDialog',
          iconName: 'webhook',
          sequenceNum: 30,
        ),
      ],
    ),
    MenuItem(
      title: 'Rooms',
      route: '/rooms',
      iconName: 'bed',
      sequenceNum: 30,
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
      ],
    ),
    MenuItem(
      title: 'Reservations',
      route: '/reservations',
      iconName: 'event',
      sequenceNum: 40,
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
        MenuItem(
          title: 'Purchase Orders',
          widgetName: 'PurchaseOrder',
          iconName: 'home',
          sequenceNum: 30,
        ),
        MenuItem(
          title: 'Suppliers',
          widgetName: 'SupplierList',
          iconName: 'business',
          sequenceNum: 40,
        ),
      ],
    ),
    MenuItem(
      title: 'In/Out',
      route: '/checkInOut',
      iconName: 'login',
      sequenceNum: 50,
      children: [
        MenuItem(
          title: 'Check In',
          widgetName: 'CheckInList',
          iconName: 'home',
          sequenceNum: 10,
        ),
        MenuItem(
          title: 'Check Out',
          widgetName: 'CheckOutList',
          iconName: 'home',
          sequenceNum: 20,
        ),
      ],
    ),
    MenuItem(
      title: 'Acct Sales',
      route: '/acct-sales',
      iconName: 'receipt_long',
      sequenceNum: 60,
      children: [
        MenuItem(
          title: 'Sales Invoices',
          widgetName: 'SalesInvoiceList',
          iconName: 'shopping_cart',
          sequenceNum: 10,
        ),
      ],
    ),
  ],
);

GoRouter createHotelTestRouter() {
  return createStaticAppRouter(
    menuConfig: hotelTestMenuConfig,
    appTitle: 'GrowERP Hotel',
    widgetBuilder: (route) => const GanttForm(),
    dashboard: const GanttForm(),
    tabWidgetLoader: (widgetName, args) => switch (widgetName) {
      'CompanyForm' => ShowCompanyDialog(
        Company(role: Role.company),
        key: const Key('CompanyForm'),
        dialog: false,
      ),
      'UserListEmployee' => const UserList(
        key: Key('UserListEmployee'),
        role: Role.company,
      ),
      'WebsiteDialog' => const WebsiteDialog(key: Key('WebsiteDialog')),
      'AssetList' => const AssetList(key: Key('AssetList')),
      'ProductList' => const ProductList(key: Key('ProductList')),
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
      'PurchaseOrder' => const FinDocList(
        key: Key('PurchaseOrder'),
        sales: false,
        docType: FinDocType.order,
      ),
      'SupplierList' => const CompanyUserList(
        key: Key('SupplierList'),
        role: Role.supplier,
      ),
      'SalesInvoiceList' => const FinDocList(
        key: Key('SalesInvoiceList'),
        sales: true,
        docType: FinDocType.invoice,
      ),
      // The backend (HOTEL_CHECKINOUT) menu uses the registered order-list
      // names CheckInList/CheckOutList (an order list filtered by status); the
      // rendered widget keeps the Key('CheckIn')/Key('CheckOut') that
      // selectCheckInOut/selectCheckOut wait on.
      'CheckInList' => const FinDocList(
        key: Key('CheckIn'),
        sales: true,
        docType: FinDocType.order,
        onlyRental: true,
        status: FinDocStatusVal.created,
      ),
      'CheckOutList' => const FinDocList(
        key: Key('CheckOut'),
        sales: true,
        docType: FinDocType.order,
        onlyRental: true,
        status: FinDocStatusVal.approved,
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

Future<void> selectRoomTypes(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'ProductList', 'Room Types');
}

Future<void> selectRooms(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rooms', 'AssetList');
}

Future<void> selectUserCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
    tester,
    '/reservations',
    'CompanyListCustomer',
    'Customers',
  );
}

Future<void> selectCompanyCustomers(WidgetTester tester) async {
  await CommonTest.selectOption(
    tester,
    '/reservations',
    'CompanyListCustomer',
    'Customers',
  );
}

Future<void> selectReservations(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/reservations', 'SalesOrder');
}

Future<void> selectSalesInvoices(WidgetTester tester) async {
  await CommonTest.gotoMainMenu(tester);
  await CommonTest.selectOption(
    tester,
    '/acct-sales',
    'SalesInvoiceList',
    'Sales Invoices',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  String classificationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets("test room reservation", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createHotelTestRouter(),
      hotelTestMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
      clear: true,
      title: 'Hotel reservation Test',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"assets": roomsHotel, "users": customers},
    );
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.tapByKey(tester, 'refresh');
    await createRoomReservation(tester, roomReservations);
    await selectReservations(tester);
    await FinDocTest.checkFinDocDetail(
      tester,
      FinDocType.order,
      rental: true,
      classificationId: 'AppHotel',
    );
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveOrders(tester, classificationId: classificationId);
    await selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await CommonTest.gotoMainMenu(tester);
    await selectReservations(tester);
    await OrderTest.completeOrders(tester, classificationId: classificationId);
    await OrderTest.checkOrderCompleted(
      tester,
      classificationId: classificationId,
    );
    await CommonTest.logout(tester);
  }, skip: false);
}

Future<void> createRoomReservation(
  WidgetTester tester,
  List<FinDoc> finDocs,
) async {
  SaveTest test = await PersistFunctions.getTest();
  List<FinDoc> newOrders = [];
  for (FinDoc finDoc in finDocs) {
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.tapByKey(tester, 'customer');
    await CommonTest.tapByText(tester, finDoc.otherUser!.lastName!);
    await CommonTest.tapByKey(tester, 'product', seconds: CommonTest.waitTime);
    await CommonTest.tapByText(tester, finDoc.items[0].description!);
    await CommonTest.enterDate(
      tester,
      'setDate',
      finDoc.items[0].rentalFromDate!,
      usDate: true,
    );
    expect(
      CommonTest.getDateTimeFormField('setDate').dateOnly(),
      finDoc.items[0].rentalFromDate.dateOnly(),
    );
    await CommonTest.enterText(
      tester,
      'quantity',
      finDoc.items[0].quantity.toString(),
    );
    await CommonTest.drag(tester);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await selectReservations(tester);
    await CommonTest.tapByKey(tester, 'id0');
    List<FinDocItem> newItems = List.of(finDoc.items);
    for (int index = 0; index < finDoc.items.length; index++) {
      var productId = CommonTest.getTextField('itemProductId$index');
      FinDocItem newItem = finDoc.items[index].copyWith(
        product: Product(pseudoId: productId),
      );
      newItems[index] = newItem;
    }
    await CommonTest.tapByKey(tester, 'cancel');
    newOrders.add(
      finDoc.copyWith(
        orderId: CommonTest.getTextField('id0'),
        pseudoId: CommonTest.getTextField('id0'),
        items: newItems,
      ),
    );
  }
  await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
}
