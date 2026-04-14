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

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin/main.dart' show delegates, getAdminBlocProviders;

/*
app: admin
screens:
  - route: /             title: "Dashboard"         wait_key: refresh
  - route: /companies    tab: Company               title: "Company detail"
  - route: /companies    tab: Employees             title: "Company employees"
  - route: /acct-ledger  tab: Ledger                title: "Ledger"
  - route: /orders       tab: salesOrders           title: "Orders"
*/

const adminScreenshotMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADMIN_SCREENSHOT',
  appId: 'admin',
  name: 'Admin Screenshot Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'ADMIN_MAIN',
      title: 'main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'AdminDashboard',
    ),
    MenuItem(
      menuItemId: 'ADMIN_ORG',
      title: 'organization',
      route: '/companies',
      iconName: 'business',
      sequenceNum: 20,
      children: [
        MenuItem(
          menuItemId: 'ADMIN_ORG_COMPANY',
          title: 'company',
          widgetName: 'ShowCompanyDialog',
          sequenceNum: 10,
        ),
        MenuItem(
          menuItemId: 'ADMIN_ORG_USERS',
          title: 'employees',
          widgetName: 'UserListEmployee',
          sequenceNum: 20,
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'ADMIN_ACC_LEDGER',
      title: 'Acct Ledger',
      route: '/acct-ledger',
      iconName: 'account_balance',
      sequenceNum: 72,
      children: [
        MenuItem(
          menuItemId: 'ADMIN_ACCL_TREE',
          title: 'Ledger',
          widgetName: 'LedgerTreeForm',
          sequenceNum: 10,
        ),
      ],
    ),
    MenuItem(
      menuItemId: 'ADMIN_ORDERS',
      title: 'orders',
      route: '/orders',
      iconName: 'shopping_cart',
      sequenceNum: 50,
      children: [
        MenuItem(
          menuItemId: 'ADMIN_ORD_SALES',
          title: 'salesOrders',
          widgetName: 'SalesOrderList',
          sequenceNum: 10,
        ),
      ],
    ),
  ],
);

class AdminScreenshotDashboard extends StatelessWidget {
  const AdminScreenshotDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;
        final dashboardOptions =
            adminScreenshotMenuConfig.menuItems
                .where(
                  (item) =>
                      item.isActive &&
                      item.route != null &&
                      item.route != '/' &&
                      item.route != '/about',
                )
                .toList()
              ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DashboardGrid(
            items: dashboardOptions,
            stats: stats,
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoad());
            },
          ),
        );
      },
    );
  }
}

GoRouter createAdminScreenshotRouter() {
  WidgetRegistry.clear();
  WidgetRegistry.register(getUserCompanyWidgets());
  WidgetRegistry.register(getOrderAccountingWidgets());

  return createStaticAppRouter(
    menuConfig: adminScreenshotMenuConfig,
    appTitle: 'GrowERP Administrator',
    widgetBuilder: (route) => switch (route) {
      '/companies' => const SizedBox.shrink(),
      '/acct-ledger' => const SizedBox.shrink(),
      '/orders' => const SizedBox.shrink(),
      _ => const SizedBox.shrink(),
    },
    dashboard: const AdminScreenshotDashboard(),
    tabWidgetLoader: (name, args) => WidgetRegistry.getWidget(name, args),
  );
}

const _screenshotsDir = String.fromEnvironment(
  'SCREENSHOTS_DIR',
  defaultValue: 'screenshots',
);

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final ui.Image image = await boundary.toImage(
    pixelRatio: tester.view.devicePixelRatio,
  );
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  if (bytes == null) {
    debugPrint(
      'WARNING: _screenshot("$name") — toByteData returned null, skipping',
    );
    return;
  }
  final outPath = '$_screenshotsDir/$name.png';
  debugPrint('Writing screenshot -> $outPath');
  final file = await File(outPath).create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
}

Future<void> _goTo(
  WidgetTester tester, {
  required String route,
  String? tab,
}) async {
  await CommonTest.tapByKey(tester, 'tap$route');
  await tester.pumpAndSettle(const Duration(seconds: 2));
  if (tab != null) {
    await CommonTest.tapByText(tester, tab);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}

Future<void> _waitForAnyKey(WidgetTester tester, List<String> keys) async {
  bool found = false;
  for (int i = 0; i < 12; i++) {
    found = keys.any((key) => tester.any(find.byKey(Key(key))));
    if (found) return;
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(
    found,
    isTrue,
    reason:
        'Timed out waiting for any of these keys to appear: ${keys.join(', ')}',
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const classificationId = 'AppAdmin';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('admin store screenshots', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createAdminScreenshotRouter(),
      adminScreenshotMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getAdminBlocProviders(restClient, classificationId),
      classificationId: classificationId,
      clear: true,
      title: 'Admin Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(tester);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await _waitForAnyKey(tester, ['refresh', 'tap/companies']);
    await _screenshot(binding, tester, 'dashboard');

    await _goTo(tester, route: '/companies', tab: 'company');
    await _waitForAnyKey(tester, ['CompanyForm', 'addNewUser']);
    await _screenshot(binding, tester, 'company_detail');

    await _goTo(tester, route: '/companies', tab: 'employees');
    await _waitForAnyKey(tester, ['addNewUser', 'userItem']);
    await _screenshot(binding, tester, 'company_employees');

    await _goTo(tester, route: '/acct-ledger', tab: 'Ledger');
    await _waitForAnyKey(tester, ['tap/acct-ledger', 'tap/orders']);
    await _screenshot(binding, tester, 'ledger');

    await _goTo(tester, route: '/orders', tab: 'salesOrders');
    await _waitForAnyKey(tester, ['addNew', 'finDocItem']);
    await _screenshot(binding, tester, 'orders');
  });
}
