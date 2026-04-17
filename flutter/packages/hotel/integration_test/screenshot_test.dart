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
app: hotel
screens:
  - route: /             title: "Dashboard"         wait_key: refresh
  - route: /myHotel     tab: Company               title: "Hotel detail"
  - route: /rooms                                    title: "Room list"
  - route: /rooms    tab: Products                  title: "Room Categories"
  - route: /reservations                             title: "Room reservations"
  - route: /acct-ledger  tab: Ledger                title: "Ledger"
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
import 'package:hotel/main.dart';
import 'package:hotel/views/gantt_form.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal config — provides appId so TopApp auto-creates MenuConfigBloc.
// Real menu items are fetched from the backend after login.
const _hotelMenuConfig = MenuConfiguration(
  menuConfigurationId: 'HOTEL_DEFAULT',
  appId: 'hotel',
  name: 'Hotel',
  menuItems: [],
);

GoRouter createHotelScreenshotRouter() {
  WidgetRegistry.clear();
  for (final reg in hotelWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_hotelMenuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'HOTEL_DEFAULT',
      dashboardBuilder: () => const GanttForm(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Hotel',
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
      '${Directory.systemTemp.path}/growerp_screenshots/hotel',
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

Future<void> _closeDialogIfPresent(WidgetTester tester) async {
  final cancel = find.byKey(const Key('cancel'));
  if (tester.any(cancel)) {
    await tester.tap(cancel.last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
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
      _hotelMenuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getHotelBlocProviders(restClient, classificationId),
      classificationId: classificationId,
      clear: true,
      title: 'Hotel Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(tester, demoData: true);

    await _waitForAnyKey(tester, ['refresh', 'tap/myHotel']);
    await _screenshot(binding, tester, 'dashboard');

    await _selectOption(
      tester,
      route: '/myHotel',
      formKey: 'CompanyForm',
      tab: 'Company',
    );
    await _screenshot(binding, tester, 'hotel_detail');
    await _closeDialogIfPresent(tester);

    await _selectOption(
      tester,
      route: '/rooms',
      formKey: '/rooms',
    );
    await _screenshot(binding, tester, 'room_list');

    await _selectOption(
      tester,
      route: '/rooms',
      formKey: '/rooms',
      tab: 'Products',
    );
    await _screenshot(binding, tester, 'room_categories');

    await _selectOption(
      tester,
      route: '/reservations',
      formKey: '/reservations',
    );
    await _screenshot(binding, tester, 'reservations');

    await _selectOption(
      tester,
      route: '/acct-ledger',
      formKey: '/acct-ledger',
    );
    await _screenshot(binding, tester, 'ledger');
  });
}
