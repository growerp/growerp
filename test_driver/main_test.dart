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
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  // Load environmental variables
  String imagePrefix = Platform.environment['imagePrefix'] ?? '?';
  bool isPhone = false;

  Future<void> takeScreenshot(
      FlutterDriver driver, String form, String name) async {
    if (imagePrefix != '?') {
      await driver.waitFor(find.byValueKey(form),
          timeout: Duration(seconds: 20));
      final List<int> pixels = await driver.screenshot();
      final File file = File('$imagePrefix$name.png');
      await file.writeAsBytes(pixels);
    }
  }

  Future<bool> isPresent(SerializableFinder finder, FlutterDriver driver,
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await driver.waitFor(finder, timeout: timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> tapButton(FlutterDriver driver, button) async {
    if (isPhone) {
      // open drawer when phone
      final drawerFinder = find.byTooltip('Open navigation menu');
      await driver.waitFor(drawerFinder, timeout: Duration(seconds: 20));
      await driver.tap(drawerFinder);
    }
    final buttonKey = find.byValueKey(button);
    await driver.scrollIntoView(buttonKey);
    await driver.tap(buttonKey);
  }

  group('Admin Home Page test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      print('=== setup driver ===');
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      driver.close();
    });

    test('check flutter driver health', () async {
      print('=== checking driver ===');
      Health health = await driver.checkHealth();
      expect(health.status, HealthStatus.ok);
    });

    test('Menu Test', () async {
      print('=== start menu test===');
      // check first if already logged in
      if (await isPresent(find.byValueKey('DashBoardForm'), driver)) {
        print('======already logged in');
      } else {
        print('======logging in');
        // check if company exist when not create
        if (await isPresent(find.byValueKey('loginButton'), driver)) {
          print('company already created, no need to create new');
          print('====company exist=======');
        } else {
          print('===create new company=====');
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
      isPhone = await isPresent(find.byTooltip('Open navigation menu'), driver);
      await takeScreenshot(driver, 'GanttForm', 'dashboard');

      //company
      await tapButton(driver, 'tap/company');
      await takeScreenshot(driver, 'CompanyInfoForm', 'company');

      //rooms
      await tapButton(driver, 'tap/rooms');
      await takeScreenshot(driver, 'AssetsForm', 'catalog');

      //reservations
      await tapButton(driver, 'tap/reservations');
      await takeScreenshot(driver, 'FinDocsForm', 'sales');

      // checkInOut
      await tapButton(driver, 'tap/checkInOut');

      //accounting
      await tapButton(driver, 'tap/accounting');
      await takeScreenshot(driver, 'AcctDashBoard', 'accounting');

      // accounting sales
      await tapButton(driver, 'tap/acctSales');

      // accounting purchase
      await tapButton(driver, 'tap/acctPurchase');

      // ledger
      await tapButton(driver, 'tap/ledger');
      await takeScreenshot(driver, 'LedgerTreeForm', 'ledger');

      // back to main
      await tapButton(driver, 'tap/');

      // logout
      await driver.tap(find.byValueKey('logoutButton'));
    }, timeout: Timeout(Duration(seconds: 600)));
  });
}
