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
import 'package:flutter/material.dart';
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
    if (expected != null) {
      debugPrint("checking  ${itemToFind.serialize()['keyValueString']}");
    }
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
      await driver.waitFor(drawerFinder, timeout: const Duration(seconds: 20));
      await driver.tap(drawerFinder);
      //await driver.waitFor(find.byValueKey('drawer'));
    }
    final buttonKey = find.byValueKey(button);
    await driver.scrollIntoView(buttonKey);
    await driver.tap(buttonKey);
  }

  Future<void> createCompanyAndAdmin() async {
    await driver.tap(find.byValueKey('newCompButton'));
    // firstname
    await driver.waitFor(find.byValueKey('firstName'));
    await driver.tap(find.byValueKey('firstName'));
    await driver.enterText('Peter');
    // lastname
    await driver.waitFor(find.byValueKey('lastName'));
    await driver.tap(find.byValueKey('lastName'));
    await driver.enterText('Pan');
    // email
    await driver.waitFor(find.byValueKey('email'));
    await driver.tap(find.byValueKey('email'));
    await driver.enterText('test@example.com');
    // companyName
    await driver.waitFor(find.byValueKey('companyName'));
    await driver.tap(find.byValueKey('companyName'));
    await driver.enterText('Peter Pan test company');
    await driver.tap(find.byValueKey('newCompany'));
    // demodata
    await driver.waitFor(find.byValueKey('demoData'));
    await driver.tap(find.byValueKey('demoData'));
    // create company
    await driver.tap(find.byValueKey('newCompany'));
  }

  Future<void> login() async {
    await driver.tap(find.byValueKey('loginButton'));
    await driver.waitFor(find.byValueKey('username'));
    await driver.tap(find.byValueKey('username'));
    await driver.enterText('test@example.com');
    await driver.waitFor(find.text('test@example.com'));
    await driver.tap(find.byValueKey('password'));
    await driver.enterText('qqqqqq9!');
    await driver.tap(find.byValueKey('login'));
  }

  group('Admin Home Page test', () {
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
      if (!await waitFor(find.byValueKey('/'))) {
        // check if any company exist when not create
        if (!await waitFor(find.byValueKey('loginButton'))) {
          await createCompanyAndAdmin();
          // allow demo data to be created
          await waitFor(find.byValueKey('loginButton'));
          await login();
        } else {
          await login();
        }
      }

      //dashboard and check if phone
      await waitFor(find.byValueKey('/'), expected: true);
      isPhone = await waitFor(find.byTooltip('Open navigation menu'));
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('dashboard');
      }

      // company logo at the top
      await driver.tap(find.byValueKey('tapCompany'));
      await waitFor(find.byValueKey('/company'), expected: true);

      // crm
      await tapMenuButton('tap/crm');
      await waitFor(find.byValueKey('/crm'), expected: true);

      //company
      await tapMenuButton('tap/company');
      await waitFor(find.byValueKey('/company'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('website');
      }

      //catalog
      await tapMenuButton('tap/catalog');
      await waitFor(find.byValueKey('/catalog'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('catalog');
      }

      //orders
      await tapMenuButton('tap/orders');
      await waitFor(find.byValueKey('/orders'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('orders');
      }

      //warehouse
      await tapMenuButton('tap/warehouse');
      await waitFor(find.byValueKey('/warehouse'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('warehouse');
      }

      //accounting
      await tapMenuButton('tap/accounting');
      await waitFor(find.byValueKey('/accounting'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('account');
      }

      // accounting sales
      await tapMenuButton('tap/acctSales');
      await waitFor(find.byValueKey('/acctSales'), expected: true);

      // accounting purchase
      await tapMenuButton('tap/acctPurchase');
      await waitFor(find.byValueKey('/acctPurchase'), expected: true);

      // ledger
      await tapMenuButton('tap/acctLedger');
      await waitFor(find.byValueKey('/acctLedger'), expected: true);
      if (imagePrefix != 'test_driver/screenshots') {
        await takeScreenshot('ledgers');
      }

      // back to main
      await tapMenuButton('tap/');
      await waitFor(find.byValueKey('/'), expected: true);

      // logout
      await driver.tap(find.byValueKey('logoutButton'));
      await waitFor(find.byValueKey('HomeFormUnAuth'), expected: true);
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
