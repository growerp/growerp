/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: depend_on_referenced_packages

/*
app: restaurant
screens:
  - route: /              title: "Floor"              wait_key: posTable0
  - route: /kitchen       title: "Kitchen"
  - route: /modifiers     title: "Modifiers"
  - route: /catalog       title: "Menu"
  - route: /shifts        title: "Shifts"
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
import 'package:growerp_pos/growerp_pos.dart';
import 'package:restaurant/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal config: provides appId so TopApp auto-creates MenuConfigBloc.
// Real menu items are fetched from the backend after login.
const _menuConfig = MenuConfiguration(
  menuConfigurationId: 'RESTAURANT_DEFAULT',
  appId: 'restaurant',
  name: 'Restaurant',
  menuItems: [],
);

GoRouter createScreenshotRouter() {
  WidgetRegistry.clear();
  for (final reg in restaurantWidgetRegistrations) {
    WidgetRegistry.register(reg);
  }
  return createDynamicAppRouter(
    [_menuConfig],
    config: DynamicRouterConfig(
      mainConfigId: 'RESTAURANT_DEFAULT',
      dashboardBuilder: () => const PosFloorScreen(),
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'GrowERP Restaurant',
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
      '${Directory.systemTemp.path}/growerp_screenshots/restaurant',
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
  const applicationId = 'AppRestaurant';

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', 'en');
  });

  testWidgets('restaurant store screenshots', (WidgetTester tester) async {
    final restClient = RestClient(await buildDioClient());

    await CommonTest.startTestApp(
      tester,
      createScreenshotRouter(),
      _menuConfig,
      delegates,
      restClient: restClient,
      blocProviders: getRestaurantAppBlocProviders(restClient, applicationId),
      applicationId: applicationId,
      clear: true,
      title: 'Restaurant Screenshots',
    );

    await CommonTest.createCompanyAndAdmin(tester, demoData: true);

    await _waitForAnyKey(tester, ['posOpenShift']);
    await CommonTest.enterText(tester, 'posOpeningFloat', '100');
    await CommonTest.tapByKey(tester, 'posOpenShift', seconds: 3);
    await _waitForAnyKey(tester, ['posTable0']);
    expect(find.text('Table 1'), findsOneWidget);
    await _screenshot(binding, tester, 'floor');

    await _selectOption(tester, route: '/kitchen', formKey: '/kitchen');
    expect(find.byType(PosKitchenScreen), findsOneWidget);
    expect(find.byKey(const Key('posTicket0')), findsOneWidget);
    await _screenshot(binding, tester, 'kitchen');

    await _selectOption(tester, route: '/modifiers', formKey: '/modifiers');
    expect(find.byType(PosModifierGroupList), findsOneWidget);
    await _screenshot(binding, tester, 'modifiers');

    await _selectOption(tester, route: '/catalog', formKey: '/catalog');
    // the menu of the restaurant, not the generic demo products
    expect(find.textContaining('Deluxe room'), findsNothing);
    await _screenshot(binding, tester, 'catalog');

    await _selectOption(tester, route: '/shifts', formKey: '/shifts');
    expect(find.byType(PosShiftList), findsOneWidget);
    await _screenshot(binding, tester, 'shifts');
  });
}
