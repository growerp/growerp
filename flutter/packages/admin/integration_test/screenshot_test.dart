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
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin/main.dart'
    show delegates, getAdminBlocProviders, adminWidgetRegistrations;
import 'package:admin/views/admin_dashboard_content.dart';

/*
app: admin
screens:
  - route: /             title: "Dashboard"         wait_key: refresh
  - route: /companies    tab: Company               title: "Company detail"
  - route: /companies    tab: Employees             title: "Company employees"
  - route: /acct-ledger                             title: "Ledger"
  - route: /orders       tab: salesOrders           title: "Orders"
*/

// Minimal config — provides appId so TopApp auto-creates MenuConfigBloc.
// Real menu items are fetched from the backend after login.
const _adminMenuConfig = MenuConfiguration(
  menuConfigurationId: 'ADMIN_DEFAULT',
  appId: 'admin',
  name: 'Admin',
  menuItems: [],
);

GoRouter createAdminScreenshotRouter() {
  WidgetRegistry.clear();
  for (final reg in adminWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_adminMenuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'ADMIN_DEFAULT',
      dashboardBuilder: () => const AdminDashboardContent(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Administrator',
    ),
  );
}

const _screenshotsDir = String.fromEnvironment(
  'SCREENSHOTS_DIR',
  defaultValue: 'screenshots',
);

Future<String> _resolveScreenshotPath(String name) async {
  final preferredDir = Directory(_screenshotsDir);
  try {
    await preferredDir.create(recursive: true);
    return '${preferredDir.path}/$name.png';
  } on FileSystemException catch (e) {
    final fallbackDir = Directory(
      '${Directory.systemTemp.path}/growerp_screenshots/admin',
    );
    await fallbackDir.create(recursive: true);
    debugPrint(
      'WARNING: could not create screenshot dir "${preferredDir.path}" '
      '(${e.osError?.message ?? e.message}); using "${fallbackDir.path}"',
    );
    return '${fallbackDir.path}/$name.png';
  }
}

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
  final outPath = await _resolveScreenshotPath(name);
  debugPrint('Writing screenshot -> $outPath');
  final file = await File(outPath).create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
}

Future<void> _selectOption(
  WidgetTester tester, {
  required String route,
  required String formKey,
  String? tab,
}) async {
  await CommonTest.selectOption(tester, route, formKey, tab);
  await tester.pumpAndSettle(const Duration(seconds: 2));
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

Future<void> _closeDialogIfPresent(WidgetTester tester) async {
  final cancel = find.byKey(const Key('cancel'));
  if (tester.any(cancel)) {
    await tester.tap(cancel.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
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
      _adminMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getAdminBlocProviders(restClient, classificationId),
      classificationId: classificationId,
      clear: true,
      title: 'Admin Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(tester, demoData: true);
    // Use pump (not pumpAndSettle) to avoid blocking on CircularProgressIndicator
    // while MenuConfigBloc fetches the real menu from the backend after login.
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    await _waitForAnyKey(tester, ['tap/companies', 'tap/acct-ledger']);
    await _screenshot(binding, tester, 'dashboard');

    await _selectOption(
      tester,
      route: '/companies',
      formKey: 'CompanyForm',
      tab: 'company',
    );
    await _waitForAnyKey(tester, ['CompanyForm', 'addNewUser']);
    await _screenshot(binding, tester, 'company_detail');
    await _closeDialogIfPresent(tester);

    await _selectOption(
      tester,
      route: '/companies',
      formKey: 'addNewUser',
      tab: 'employees',
    );
    await _waitForAnyKey(tester, ['addNewUser', 'userItem']);
    await _screenshot(binding, tester, 'company_employees');

    await _selectOption(tester, route: '/acct-ledger', formKey: '/acct-ledger');
    await _screenshot(binding, tester, 'ledger');

    await _selectOption(tester, route: '/orders', formKey: '/orders');
    await _waitForAnyKey(tester, [
      '/orders',
      'refresh',
      'addNew',
      'finDocItem',
    ]);
    await _screenshot(binding, tester, 'orders');
  });
}
