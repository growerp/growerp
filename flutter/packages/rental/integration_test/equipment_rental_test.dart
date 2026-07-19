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

// End-to-end rental flow for the equipment-hire vertical: create equipment
// (assets) and a customer, book a date-range rental order, then approve,
// invoice and complete it. Mirrors the hotel room_rental_test but runs against
// the AppRental application (equipment / AsClsEquipment instead of rooms).
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
import 'package:integration_test/integration_test.dart';
import 'package:rental/main.dart';
import 'package:growerp_rental/growerp_rental.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const rentalTestMenuConfig = MenuConfiguration(
  menuConfigurationId: 'RENTAL_TEST',
  appId: 'rental',
  name: 'Rental Test',
  menuItems: [
    MenuItem(
      title: 'Main',
      route: '/',
      widgetName: 'GanttForm',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      title: 'Equipment',
      route: '/equipment',
      iconName: 'construction',
      sequenceNum: 30,
      children: [
        MenuItem(
          title: 'Equipment',
          widgetName: 'AssetList',
          iconName: 'home',
          sequenceNum: 10,
        ),
        MenuItem(
          title: 'Equipment Types',
          widgetName: 'ProductList',
          iconName: 'home',
          sequenceNum: 20,
        ),
      ],
    ),
    MenuItem(
      title: 'Rentals',
      route: '/rentals',
      iconName: 'event',
      sequenceNum: 40,
      children: [
        MenuItem(
          title: 'Rentals',
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

GoRouter createRentalTestRouter() {
  return createStaticAppRouter(
    menuConfig: rentalTestMenuConfig,
    appTitle: 'GrowERP Rental',
    widgetBuilder: (route) => const GanttForm(),
    dashboard: const GanttForm(),
    tabWidgetLoader: (widgetName, args) => switch (widgetName) {
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
      'SalesInvoiceList' => const FinDocList(
        key: Key('SalesInvoiceList'),
        sales: true,
        docType: FinDocType.invoice,
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

Future<void> selectRentals(WidgetTester tester) async {
  await CommonTest.selectOption(tester, '/rentals', 'SalesOrder');
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
  String applicationId = 'AppRental';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets("test equipment rental", (WidgetTester tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createRentalTestRouter(),
      rentalTestMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getRentalBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Equipment rental Test',
    );
    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {"assets": equipmentRental, "users": customers},
    );
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.tapByKey(tester, 'refresh');
    await createEquipmentRental(tester, equipmentReservations);
    await selectRentals(tester);
    await FinDocTest.checkFinDocDetail(
      tester,
      FinDocType.order,
      rental: true,
      applicationId: applicationId,
    );
    await OrderTest.checkRentalSalesOrderBlocDates(tester);
    await OrderTest.approveOrders(tester, applicationId: applicationId);
    await selectSalesInvoices(tester);
    await InvoiceTest.checkInvoices(tester);
    await InvoiceTest.sendOrApproveInvoices(tester);
    await CommonTest.gotoMainMenu(tester);
    await selectRentals(tester);
    await OrderTest.completeOrders(tester, applicationId: applicationId);
    await OrderTest.checkOrderCompleted(tester, applicationId: applicationId);
    await CommonTest.logout(tester);
  }, skip: false);
}

Future<void> createEquipmentRental(
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
    await selectRentals(tester);
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
