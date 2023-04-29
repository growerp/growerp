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

import 'dart:io';
import 'dart:math';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  // Load environmental variables
  String imagePrefix =
      Platform.environment['imagePrefix'] ?? 'test_driver/screenshots';
  bool isPhone = false;
  late FlutterDriver driver;
  int random = Random.secure().nextInt(1024);
  int seq = 0;

  Future<void> takeScreenshot([String? name]) async {
    String fileName = name ?? '${random.toString()}-${(++seq).toString()}';
    fileName = '$imagePrefix$fileName.jpg';
    final List<int> pixels = await driver.screenshot();
    final File file = File(fileName);
    await file.writeAsBytes(pixels);
  }

  // find by valueKey or SerializableFinder
  // take a screen shot if 'expected' is provided AND not the same as result
  Future<bool> waitFor(SerializableFinder itemToFind,
      {bool? expected, Duration timeout = const Duration(seconds: 10)}) async {
    if (expected != null)
      debugPrint("====checking  ${itemToFind.serialize()['keyValueString']}");
    try {
      await driver.waitFor(itemToFind, timeout: timeout);
      if (expected != null && expected != true) {
        takeScreenshot();
        expect(true, false,
            reason:
                "=== should not find but did: ${itemToFind.serialize()['keyValueString']}");
      }
      return Future.value(true);
    } catch (e) {
      if (expected != null && expected != false) {
        takeScreenshot();
        expect(true, false,
            reason:
                "=== could not find: ${itemToFind.serialize()['keyValueString']}");
      }
      return Future.value(false);
    }
  }

  Future<void> tapMenuButton(button) async {
    if (isPhone) {
      // open drawer when phone
      final drawerFinder = find.byTooltip('Open navigation menu');
      await driver.waitFor(drawerFinder, timeout: Duration(seconds: 20));
      await driver.tap(drawerFinder);
      //await driver.waitFor(find.byValueKey('drawer'));
    }
    final buttonKey = find.byValueKey(button);
    await driver.scrollIntoView(buttonKey);
    await driver.tap(buttonKey);
  }

  group('Hotel Home Page test', () {
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      driver.close();
    });

    test('check flutter driver health', () async {
      Health health = await driver.checkHealth();
      expect(health.status, HealthStatus.ok);
    });
    test('Debug data Test', () async {
      // check first if already logged in
      if (await waitFor(find.byValueKey('GanttForm'))) {
      } else {
        // check if company exist when not create
        if (await waitFor(find.byValueKey('loginButton'))) {
        } else {
          await driver.tap(find.byValueKey('newCompButton'));
          await driver.tap(find.byValueKey('newCompany'));
          // allow demo data to be created
          await Future.delayed(const Duration(seconds: 20));
        }

        // login
        await driver.tap(find.byValueKey('loginButton'));
        await driver.tap(find.byValueKey('login'));
      }

      //dashboard and check if phone
      await driver.waitFor(find.byValueKey('GanttForm'));
      isPhone = await waitFor(find.byTooltip('Open navigation menu'));
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('gantt');

      // user top left
      await tapMenuButton('tapUser');
      await waitFor(find.byValueKey('UserDialogAdmin'), expected: true);
      await driver.tap(find.byValueKey('cancel'));
      // close drawer for phone
      if (isPhone) await driver.tap(find.byValueKey('tap/'));

      // company logo at the top
      await driver.tap(find.byValueKey('tapCompany'));
      await waitFor(find.byValueKey('/company'), expected: true);
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('company');

      //rooms
      await tapMenuButton('tap/catalog');
      await waitFor(find.byValueKey('/catalog'), expected: true);
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('catalog');

      //reservations
      await tapMenuButton('tap/sales');
      await waitFor(find.byValueKey('/sales'), expected: true);
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('sales');

      // checkInOut
      await tapMenuButton('tap/checkInOut');
      await waitFor(find.byValueKey('/checkInOut'), expected: true);

      //accounting
      await tapMenuButton('tap/accounting');
      await waitFor(find.byValueKey('/accounting'), expected: true);
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('accounting');

      // accounting sales
      await tapMenuButton('tap/acctSales');
      await waitFor(find.byValueKey('/acctSales'), expected: true);

      // accounting purchase
      await tapMenuButton('tap/acctPurchase');
      await waitFor(find.byValueKey('/acctPurchase'), expected: true);

      // ledger
      await tapMenuButton('tap/ledger');
      await waitFor(find.byValueKey('/ledger'), expected: true);
      if (imagePrefix != 'test_driver/screenshots')
        await takeScreenshot('ledger');

      // back to main
      await tapMenuButton('tap/');
      await waitFor(find.byValueKey('/'), expected: true);

      // logout
      await driver.tap(find.byValueKey('logoutButton'));
      await waitFor(find.byValueKey('HomeFormUnAuth'), expected: true);
    }, timeout: Timeout(Duration(seconds: 1200)));
  });
}
