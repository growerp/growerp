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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

/// Integration test steps for the cash book categories: a company starts with
/// a short default selection out of its ledger accounts, can switch a category
/// off and add one of its own.
class CashBookCategoryTest {
  /// switched on by default for every company
  static const defaultExpense = 'Rent Expense';
  static const defaultIncome = 'Product Sales';

  /// an expense account which exists but is not a default category
  static const unusedExpense = 'Data Processing';

  static Future<void> selectCategories(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/accounting/cashbook-categories',
      'CashBookCategoryList',
    );
  }

  static Future<void> checkDefaults(WidgetTester tester) async {
    await CommonTest.waitForKey(tester, 'name0');
    // expenses are shown first, in use on top
    expect(await _isUsed(tester, defaultExpense), true);
    await CommonTest.tapByKey(tester, 'filterIn', seconds: CommonTest.waitTime);
    expect(await _isUsed(tester, defaultIncome), true);
    await CommonTest.tapByKey(
      tester,
      'filterOut',
      seconds: CommonTest.waitTime,
    );
  }

  /// switch a category off and check the cash book no longer offers it
  static Future<void> switchOff(WidgetTester tester, String name) async {
    final index = await _find(tester, name);
    expect(index, isNot(-1), reason: 'category $name should be in the list');
    await CommonTest.tapByKey(tester, 'inUse$index');
    await CommonTest.waitForSnackbarToGo(tester);
    expect(await _isUsed(tester, name), false);
  }

  static Future<void> switchOn(WidgetTester tester, String name) async {
    final index = await _find(tester, name);
    if (index == -1) return;
    await CommonTest.tapByKey(tester, 'inUse$index');
    await CommonTest.waitForSnackbarToGo(tester);
  }

  static Future<void> addCategory(
    WidgetTester tester,
    String name, {
    bool isIncome = false,
  }) async {
    await _clearSearch(tester);
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.checkWidgetKey(tester, 'CashBookCategoryDialog');
    await CommonTest.enterText(tester, 'name', name);
    await CommonTest.tapByKey(tester, isIncome ? 'dirIn' : 'dirOut');
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    expect(await _isUsed(tester, name), true);
  }

  static Future<void> rename(
    WidgetTester tester,
    String name,
    String newName,
  ) async {
    final index = await _find(tester, name);
    expect(index, isNot(-1), reason: 'category $name should be in the list');
    await CommonTest.tapByKey(tester, 'name$index');
    await CommonTest.checkWidgetKey(tester, 'CashBookCategoryDialog');
    await CommonTest.enterText(tester, 'name', newName);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    expect(await _find(tester, newName), isNot(-1));
  }

  /// the cash book dialog only offers the categories which are in use
  static Future<void> checkCashBookOffers(
    WidgetTester tester, {
    required List<String> present,
    required List<String> absent,
  }) async {
    await _clearSearch(tester);
    await CommonTest.selectOption(
      tester,
      '/accounting/cashbook',
      'CashBookList',
    );
    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.checkWidgetKey(tester, 'CashBookDialog');
    await CommonTest.tapByKey(tester, 'dirOut');
    // read the options from the dropdown itself: the menu only builds the
    // options which fit on the screen
    // the options of a closed dropdown are not in the widget tree, read them
    // from the DropdownButton the form field builds
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const Key('category')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    final options = (dropdown.items ?? [])
        .map((item) => (item.child as Text).data ?? '')
        .toList();
    for (final name in present) {
      expect(
        options.contains(name),
        true,
        reason: '$name should be offered as a category, offered: $options',
      );
    }
    for (final name in absent) {
      expect(
        options.contains(name),
        false,
        reason: '$name should not be offered as a category',
      );
    }
    await CommonTest.tapByKey(tester, 'cancel');
  }

  static Future<void> _clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  static Future<int> _find(WidgetTester tester, String name) async {
    await CommonTest.enterText(tester, 'searchField', name);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    for (int index = 0; index < 10; index++) {
      if (!tester.any(find.byKey(Key('name$index')))) break;
      if (CommonTest.getTextField('name$index') == name) return index;
    }
    return -1;
  }

  static Future<bool> _isUsed(WidgetTester tester, String name) async {
    final index = await _find(tester, name);
    if (index == -1) return false;
    return CommonTest.getSwitch('inUse$index');
  }
}
