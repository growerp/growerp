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

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:hotel/main.dart';
import 'package:hotel/views/accounting_form.dart';
import 'package:hotel/views/gantt_form.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Static MenuConfiguration for the screenshot test router
// ---------------------------------------------------------------------------
const hotelScreenshotMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_SCREENSHOT',
  appId: 'hotel',
  name: 'Hotel Screenshot Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'HOTEL_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'GanttForm',
    ),
    MenuItem(
      menuItemId: 'HOTEL_ROOMS',
      title: 'Rooms',
      route: '/rooms',
      iconName: 'hotel',
      sequenceNum: 20,
      children: [
        MenuItem(
          menuItemId: 'HOTEL_ASSET_LIST',
          title: 'Rooms',
          widgetName: 'AssetList',
          sequenceNum: 10,
        ),
        MenuItem(
          menuItemId: 'HOTEL_PRODUCT_LIST',
          title: 'Room Types',
          widgetName: 'ProductList',
          sequenceNum: 20,
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'HOTEL_MY_HOTEL',
      title: 'My Hotel',
      route: '/myHotel',
      iconName: 'business',
      sequenceNum: 30,
      children: [
        MenuItem(
          menuItemId: 'HOTEL_COMPANY',
          title: 'Company',
          widgetName: 'ShowCompanyDialog',
          sequenceNum: 10,
        ),
        MenuItem(
          menuItemId: 'HOTEL_EMPLOYEES',
          title: 'Employees',
          widgetName: 'UserListEmployee',
          sequenceNum: 20,
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'HOTEL_ACCOUNTING',
      title: 'Accounting',
      route: '/accounting',
      iconName: 'account_balance',
      sequenceNum: 40,
      widgetName: 'AccountingForm',
    ),
  ],
);

GoRouter createHotelScreenshotRouter() {
  WidgetRegistry.clear();
  WidgetRegistry.register(getUserCompanyWidgets());
  WidgetRegistry.register(getCatalogWidgets());
  WidgetRegistry.register(getInventoryWidgets());
  WidgetRegistry.register(getOrderAccountingWidgets());
  WidgetRegistry.register({
    'GanttForm': (args) => const GanttForm(),
    'AccountingForm': (args) => const AccountingForm(),
  });

  return createStaticAppRouter(
    menuConfig: hotelScreenshotMenuConfig,
    appTitle: 'GrowERP Hotel',
    widgetBuilder: (route) => switch (route) {
      '/accounting' => const AccountingForm(),
      _ => const SizedBox.shrink(),
    },
    dashboard: const GanttForm(),
    tabWidgetLoader: (name, args) => WidgetRegistry.getWidget(name, args),
  );
}

// ---------------------------------------------------------------------------
// Screenshot helper — writes PNG to screenshots/<name>.png on disk.
// Called by the test_driver onScreenshot callback when using flutter drive.
// ---------------------------------------------------------------------------
Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await CommonTest.takeScreenShot(
    binding: binding,
    tester: tester,
    screenShotName: name,
  );
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const classificationId = 'AppHotel';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('hotel store screenshots', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createHotelScreenshotRouter(),
      hotelScreenshotMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
      clear: true,
      title: 'Hotel Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(
      tester,
      testData: {
        'products': products.sublist(0, 2),
        'users': employees.sublist(0, 2),
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── 1. Main menu (GanttForm home screen) ────────────────────────────────
    await CommonTest.waitForKey(tester, 'refresh');
    await _screenshot(binding, tester, 'mainmenu');

    // ── 2. Product list (Room Types tab under /rooms) ────────────────────────
    await CommonTest.selectOption(tester, '/rooms', 'addNew', 'Room Types');
    await _screenshot(binding, tester, 'product_list');

    // ── 3. Product detail (open first list item) ─────────────────────────────
    if (tester.any(find.byKey(const Key('productItem')))) {
      await tester.tap(find.byKey(const Key('productItem')).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _screenshot(binding, tester, 'product_detail');
      // Dismiss dialog to return to list
      final NavigatorState nav = tester.state(find.byType(Navigator).last);
      nav.pop();
      await tester.pumpAndSettle();
    }

    // ── 4. Employee list (Employees tab under /myHotel) ──────────────────────
    await CommonTest.selectOption(
      tester,
      '/myHotel',
      'addNewUser',
      'Employees',
    );
    await _screenshot(binding, tester, 'employee_list');

    // ── 5. Employee detail (open first list item) ─────────────────────────────
    if (tester.any(find.byKey(const Key('userItem')))) {
      await tester.tap(find.byKey(const Key('userItem')).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _screenshot(binding, tester, 'employee_detail');
      final NavigatorState nav = tester.state(find.byType(Navigator).last);
      nav.pop();
      await tester.pumpAndSettle();
    }

    // ── 6. Ledger / Accounting dashboard ────────────────────────────────────
    await CommonTest.selectOption(tester, '/accounting', 'AcctDashBoard');
    await _screenshot(binding, tester, 'ledger');
  });
}
