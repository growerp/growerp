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

/*
app: rental
screens:
  - route: /              title: "Dashboard"          wait_key: refresh
  - route: /equipment     title: "Equipment"
  - route: /rentals       title: "Rentals"
  - route: /pickupReturn  title: "Pickup and return"
  - route: /statistics    title: "Utilisation"
  - route: /acct-ledger   title: "Ledger"
*/

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:rental/main.dart';
import 'package:growerp_rental/growerp_rental.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal config — provides appId so TopApp auto-creates MenuConfigBloc.
// Real menu items are fetched from the backend after login.
const _rentalMenuConfig = MenuConfiguration(
  menuConfigurationId: 'RENTAL_DEFAULT',
  appId: 'rental',
  name: 'Rental',
  menuItems: [],
);

GoRouter createRentalScreenshotRouter() {
  WidgetRegistry.clear();
  for (final reg in rentalWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_rentalMenuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'RENTAL_DEFAULT',
      dashboardBuilder: () => const GanttForm(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Rental',
    ),
  );
}

// ---------------------------------------------------------------------------
// Screenshot helper — captures via RenderRepaintBoundary.toImage() and
// writes PNG to <SCREENSHOTS_DIR>/<name>.png on disk.
//
// SCREENSHOTS_DIR is passed via --dart-define so the absolute container path
// is used regardless of what CWD the Linux binary happens to run with.
// Works with `flutter test -d linux` without any platform channel.
// ---------------------------------------------------------------------------

// Absolute path injected by run_screenshots.sh; fallback keeps local dev working.
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
      '${Directory.systemTemp.path}/growerp_screenshots/rental',
    );
    await fallbackDir.create(recursive: true);
    // ignore: avoid_print
    print(
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
  // `.first` in pre-order DFS = the outermost RepaintBoundary (parent before
  // children), which wraps the full viewport.
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
    // ignore: avoid_print
    print('WARNING: _screenshot("$name") — toByteData returned null, skipping');
    return;
  }
  final outPath = await _resolveScreenshotPath(name);
  // ignore: avoid_print
  print('Writing screenshot → $outPath');
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

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const applicationId = 'AppRental';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('rental store screenshots', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createRentalScreenshotRouter(),
      _rentalMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getRentalBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Rental Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(tester, demoData: true);

    await _waitForAnyKey(tester, ['refresh', 'tap/equipment']);
    await _screenshot(binding, tester, 'dashboard');

    await _selectOption(tester, route: '/equipment', formKey: '/equipment');
    await _screenshot(binding, tester, 'equipment');

    await _selectOption(tester, route: '/rentals', formKey: '/rentals');
    await _screenshot(binding, tester, 'rentals');

    await _selectOption(
      tester,
      route: '/pickupReturn',
      formKey: '/pickupReturn',
    );
    await _screenshot(binding, tester, 'pickup_return');

    await _selectOption(tester, route: '/statistics', formKey: '/statistics');
    await _screenshot(binding, tester, 'utilisation');

    await _selectOption(tester, route: '/acct-ledger', formKey: '/acct-ledger');
    await _screenshot(binding, tester, 'ledger');
  });
}
