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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../domains/domains.dart';
import '../../common/integration_test/common_test.dart';

class AuthTest {
  //===============================high level tests ============================

  static Future<void> createNewAdminAndCompany(
      WidgetTester tester, User user, Company company) async {
    await logoutIfRequired(tester);
    await CommonTest.checkText(tester, 'Login / New company'); // initial screen
    await pressNewCompany(tester);
    await enterFirstName(tester, user.firstName!);
    await enterLastname(tester, user.lastName!);
    await enterEmailAddress(tester, user.email!);
    await enterCompanyName(tester, user.companyName!);
    await enterCurrency(tester, company.currency!);
    await CommonTest.drag(tester, seconds: 10);
    await clearDemoData(tester);
    await CommonTest.drag(tester, seconds: 5);
    await pressRegisterAndcreateNewAdminAndCompany(tester);
  }

  static Future<void> login(
      WidgetTester tester, String loginName, String password) async {
    await pressLoginWithExistingId(tester);
    await enterLoginName(tester, loginName);
    await enterPassword(tester, password);
    await pressLogin(tester);
    await CommonTest.checkText(tester, 'Main'); // dashboard
  }

  static Future<void> loginIfRequired(
      WidgetTester tester, String loginName, String password) async {
    try {
      expect(find.byKey(const Key('HomeFormAuth')), findsOneWidget);
    } catch (_) {
      await login(tester, loginName, password);
    }
  }

  static Future<void> logout(WidgetTester tester) async {
    await gotoMainMenu(tester);
    await CommonTest.tapByKey(tester, 'logoutButton', seconds: 5);
    await CommonTest.checkWidgetKey(tester, 'HomeFormUnAuth');
  }

  // ===============================low level tests ============================

  static Future<void> gotoMainMenu(WidgetTester tester) async {
    await CommonTest.selectMainMenu(tester, "tap/");
  }

  static Future<void> clearDemoData(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'demoData', seconds: 5);
  }

  static Future<void> enterCompanyName(WidgetTester tester, String name) async {
    await CommonTest.enterText(tester, 'companyName', name);
  }

  static Future<void> enterCurrency(
      WidgetTester tester, Currency currency) async {
    await CommonTest.selectDropDown(tester, 'currency', currency.description!);
  }

  static Future<void> enterEmailAddress(
      WidgetTester tester, String emailAddress) async {
    await CommonTest.enterText(tester, 'email', emailAddress);
  }

  static Future<void> enterFirstName(
      WidgetTester tester, String firstName) async {
    await CommonTest.enterText(tester, 'firstName', firstName);
  }

  static Future<void> enterLastname(
      WidgetTester tester, String lastName) async {
    await CommonTest.enterText(tester, 'lastName', lastName);
  }

  static Future<void> enterLoginName(
      WidgetTester tester, String loginName) async {
    await CommonTest.enterText(tester, 'username', loginName);
  }

  static Future<void> enterPassword(
      WidgetTester tester, String password) async {
    await CommonTest.enterText(tester, 'password', password);
  }

  static Future<void> pressLoginWithExistingId(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'loginButton', seconds: 1);
  }

  static Future<void> pressLogin(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'login', seconds: 5);
  }

  static Future<void> logoutIfRequired(WidgetTester tester) async {
    try {
      expect(find.byKey(const Key('HomeFormUnAuth')), findsOneWidget);
    } catch (_) {
      // assumes still logged in, so logout
      await CommonTest.tapByKey(tester, 'logoutButton');
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('HomeFormUnAuth')), findsOneWidget);
    }
  }

  static Future<void> pressNewCompany(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'newCompButton');
  }

  static Future<void> pressRegisterAndcreateNewAdminAndCompany(
      WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'newCompany', seconds: 5);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}
