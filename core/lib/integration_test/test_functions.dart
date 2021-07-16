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

import 'dart:math';

import 'package:core/forms/@forms.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/@models.dart';

class Test {
  static String getDropdown(String key) {
    DropdownButtonFormField tff = find.byKey(Key(key)).evaluate().single.widget
        as DropdownButtonFormField;
    if (tff.initialValue is Currency) return tff.initialValue.description;
    return tff.initialValue;
  }

  static String getDropdownSearch(String key) {
    DropdownSearch tff =
        find.byKey(Key(key)).evaluate().single.widget as DropdownSearch;
    if (tff.selectedItem is Country) return tff.selectedItem.name;
    if (tff.selectedItem is ProductCategory)
      return tff.selectedItem.categoryName;
    if (tff.selectedItem is Product) return tff.selectedItem.productName;
    return tff.selectedItem.toString();
  }

  static String getTextFormField(String key) {
    TextFormField tff =
        find.byKey(Key(key)).evaluate().single.widget as TextFormField;
    return tff.controller!.text;
  }

  static String getTextField(String key) {
    Text tf = find.byKey(Key(key)).evaluate().single.widget as Text;
    return tf.data!;
  }

  static String getRandom() {
    Text tff =
        find.byKey(Key('appBarCompanyName')).evaluate().single.widget as Text;
    return tff.data!.replaceAll(new RegExp(r'[^0-9]'), '');
  }

  static bool isPhone() {
    try {
      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> login(WidgetTester tester, Widget TopApp) async {
    await tester.pumpWidget(RestartWidget(child: TopApp));
    await tester.pumpAndSettle(Duration(seconds: 5));
    try {
      expect(find.byKey(Key('DashBoardForm')), findsOneWidget);
    } catch (_) {
      await tester.tap(find.byKey(Key('loginButton')));
      await tester.pumpAndSettle(Duration(seconds: 5));
      await tester.enterText(find.byKey(Key('password')), 'qqqqqq9!');
      await tester.tap(find.byKey(Key('login')));
      await tester.pumpAndSettle(Duration(seconds: 5));
      expect(find.byKey(Key('/')), findsOneWidget);
    }
  }

  static Future<void> logout(WidgetTester tester) async {
    if (isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump(Duration(seconds: 10));
    }
    await tester.tap(find.byKey(Key('tap/')));
    await tester.tap(find.byKey(Key('logoutButton')));
    await tester.pump(Duration(seconds: 5));
    expect(find.byKey(Key('HomeFormUnAuth')), findsOneWidget,
        reason: '>>>logged out home screen not found');
  }

  static Future<void> createCategoryFromMain(WidgetTester tester) async {
    await tester.tap(find.byKey(Key('dbCatalog')));
    await tester.pump(Duration(seconds: 5));
    if (Test.isPhone())
      await tester.tap(find.byTooltip('3'));
    else
      await tester.tap(find.byKey(Key('tapCategoriesForm')));
    await tester.pump(Duration(seconds: 5));
    // enter caegories
    for (int x = 1; x < 3; x++) {
      await tester.tap(find.byKey(Key('addNew')));
      await tester.pump(Duration(seconds: 5));
      await tester.enterText(find.byKey(Key('name')), 'categoryName$x');
      await tester.enterText(find.byKey(Key('description')), 'categoryDesc$x');
      await tester.tap(find.byKey(Key('update')));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    // back to main
    if (isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    await tester.tap(find.byKey(Key('tap/')));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  static Future<void> createProductFromMain(WidgetTester tester) async {
    await createCategoryFromMain(tester); // need a category to create test
    await tester.tap(find.byKey(Key('dbCatalog')));
    await tester.pumpAndSettle(Duration(seconds: 5));
    if (Test.isPhone())
      await tester.tap(find.byTooltip('1'));
    else
      await tester.tap(find.byKey(Key('tapProductsForm')));
    await tester.pumpAndSettle(Duration(seconds: 5));
    // enter products
    for (int x = 1; x < 3; x++) {
      await tester.tap(find.byKey(Key('addNew')));
      await tester.pump(Duration(seconds: 1));
      await tester.enterText(find.byKey(Key('name')), 'productName$x');
      await tester.enterText(find.byKey(Key('description')), 'productDesc$x');
      await tester.enterText(find.byKey(Key('price')), '$x$x.$x$x');
      await tester.tap(find.byKey(Key('categoryDropDown')));
      await tester.pumpAndSettle(Duration(seconds: 1));
      await tester.tap(find.text('categoryName$x').last);
      await tester.pump(Duration(seconds: 1));
      await tester.drag(find.byKey(Key('listView')), Offset(0.0, -500.0));
      await tester.pump(Duration(seconds: 1));
      await tester.tap(find.byKey(Key('update')));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    // back to main
    if (isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    await tester.tap(find.byKey(Key('tap/')));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  static Future<void> createCompanyAndAdmin(
      WidgetTester tester, Widget TopApp) async {
    String random = Random.secure().nextInt(1024).toString();
    await tester.pumpWidget(RestartWidget(child: TopApp));
    await tester.pumpAndSettle(Duration(seconds: 10));
    try {
      expect(find.byKey(Key('HomeFormUnAuth')), findsOneWidget);
    } catch (_) {
      // assumes still logged in, so logout
      print("Dashboard logged in , needs to logout");
      await tester.tap(find.byKey(Key('logoutButton')));
      await tester.pump(Duration(seconds: 5));
      expect(find.byKey(Key('HomeFormUnAuth')), findsOneWidget,
          reason: '>>>logged out home screen not found');
    }
    // tap new company button, enter data
    await tester.tap(find.byKey(Key('newCompButton')));
    await tester.pump(Duration(seconds: 1));
    await tester.enterText(find.byKey(Key('firstName')), 'firstName');
    await tester.enterText(find.byKey(Key('lastName')), 'lastName');
    await tester.enterText(find.byKey(Key('email')), 'e$random@example.org');
    await tester.enterText(
        find.byKey(Key('companyName')), 'companyName$random');
    await tester.drag(find.byKey(Key('listView')), Offset(0.0, -500.0));
    await tester.pump(Duration(seconds: 1));
    await tester.tap(find.byKey(Key('demoData')));
    await tester.tap(find.byKey(Key('newCompany')));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }

  static Future<void> createUser(
      WidgetTester tester, String userType, String random) async {
    switch (userType) {
      case 'employee':
        await tester.tap(find.byKey(Key('dbCompany')));
        await tester.pump(Duration(seconds: 5));
        if (Test.isPhone())
          await tester.tap(find.byTooltip('3'));
        else
          await tester.tap(find.byKey(Key('tapUsersFormEmployee')));
        await tester.pump(Duration(seconds: 5));
        expect(find.byKey(Key('UsersFormEmployee')), findsOneWidget);
        for (int x in [1, 2]) {
          await tester.tap(find.byKey(Key('addNew')));
          await tester.pumpAndSettle(Duration(seconds: 5));
          await tester.enterText(find.byKey(Key('firstName')), 'firstName$x');
          await tester.enterText(find.byKey(Key('lastName')), 'employee$x');
          await tester.enterText(find.byKey(Key('username')), '$random$x');
          await tester.enterText(
              find.byKey(Key('email')), 'e$random$x@example.org');
          await tester.drag(find.byKey(Key('listView')), Offset(0.0, -500.0));
          await tester.pump(Duration(seconds: 5));
          await tester.tap(find.byKey(Key('updateUser')));
          await tester.pumpAndSettle(Duration(seconds: 5));
        }
        break;

      case 'lead':
        await tester.tap(find.byKey(Key('dbCrm')));
        await tester.pump(Duration(seconds: 5));
        if (Test.isPhone())
          await tester.tap(find.byTooltip('2'));
        else
          await tester.tap(find.byKey(Key('tapUsersFormLead')));
        await tester.pump(Duration(seconds: 5));
        expect(find.byKey(Key('UsersFormLead')), findsOneWidget);
        for (int x in [3, 4]) {
          await tester.tap(find.byKey(Key('addNew')));
          await tester.pumpAndSettle(Duration(seconds: 5));
          await tester.enterText(
              find.byKey(Key('firstName')), 'firstName${x - 2}');
          await tester.enterText(find.byKey(Key('lastName')), 'lead${x - 2}');
          await tester.enterText(find.byKey(Key('username')), '$random$x');
          await tester.enterText(
              find.byKey(Key('email')), 'e$random$x@example.org');
          await tester.drag(find.byKey(Key('listView')), Offset(0.0, -500.0));
          await tester.pump(Duration(seconds: 1));
          await tester.enterText(find.byKey(Key('newCompanyName')),
              'newCompanyName$random${x - 2}');
          await tester.tap(find.byKey(Key('updateUser')));
          await tester.pumpAndSettle(Duration(seconds: 5));
        }
        break;

      case 'customer':
        await tester.tap(find.byKey(Key('dbCrm')));
        await tester.pump(Duration(seconds: 5));
        if (Test.isPhone())
          await tester.tap(find.byTooltip('3'));
        else
          await tester.tap(find.byKey(Key('tapUsersFormCustomer')));
        await tester.pump(Duration(seconds: 5));
        expect(find.byKey(Key('UsersFormCustomer')), findsOneWidget);
        for (int x in [5, 6]) {
          await tester.tap(find.byKey(Key('addNew')));
          await tester.pumpAndSettle(Duration(seconds: 5));
          await tester.enterText(
              find.byKey(Key('firstName')), 'firstName${x - 4}');
          await tester.enterText(
              find.byKey(Key('lastName')), 'customer${x - 4}');
          await tester.enterText(find.byKey(Key('username')), '$random$x');
          await tester.enterText(
              find.byKey(Key('email')), 'e$random$x@example.org');
          await tester.drag(find.byKey(Key('listView')), Offset(0.0, -500.0));
          await tester.pump(Duration(seconds: 1));
          await tester.enterText(find.byKey(Key('newCompanyName')),
              'newCompanyName$random${x - 4}');
          await tester.tap(find.byKey(Key('updateUser')));
          await tester.pumpAndSettle(Duration(seconds: 5));
        }
        break;
    }
    // back to main
    if (isPhone()) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }
    await tester.tap(find.byKey(Key('tap/')));
    await tester.pumpAndSettle(Duration(seconds: 5));
  }
}
