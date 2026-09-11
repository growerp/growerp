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

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Integration test steps for the simplified cash book and its profit & loss
/// report. Entries are typed through the dialog; the report totals are then
/// compared with the amounts entered.
class CashBookTest {
  static final List<CashBookEntry> entries = [
    CashBookEntry(
      isIncome: true,
      amount: Decimal.parse('1200'),
      category: GlAccount(accountName: 'Product Sales'),
      description: 'Website project client A',
    ),
    CashBookEntry(
      isIncome: true,
      amount: Decimal.parse('300.50'),
      category: GlAccount(accountName: 'Product Sales'),
      description: 'Consulting hours client B',
    ),
    CashBookEntry(
      isIncome: false,
      amount: Decimal.parse('450'),
      category: GlAccount(accountName: 'Rent Expense'),
      description: 'Office rent',
    ),
    CashBookEntry(
      isIncome: false,
      amount: Decimal.parse('79.99'),
      category: GlAccount(accountName: 'Rent Expense'),
      description: 'Coworking day pass',
    ),
  ];

  static Future<void> selectCashBook(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/accounting/cashbook',
      'CashBookList',
    );
  }

  static Future<void> selectProfitLoss(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/accounting/profit-loss',
      'ProfitLossForm',
    );
  }

  static Future<void> addEntries(WidgetTester tester) async {
    for (final entry in entries) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.checkWidgetKey(tester, 'CashBookDialog');
      await _enterEntry(tester, entry);
    }
    expect(
      CommonTest.getWidgetCountByKey(tester, 'cashBookItem'),
      entries.length,
    );
    // newest first: the last entered entry is row 0
    expect(CommonTest.getTextField('name0'), entries.last.description);
  }

  static Future<void> _enterEntry(
    WidgetTester tester,
    CashBookEntry entry,
  ) async {
    await CommonTest.tapByKey(tester, entry.isIncome ? 'dirIn' : 'dirOut');
    await CommonTest.enterText(tester, 'amount', entry.amount.toString());
    await CommonTest.selectDropDown(
      tester,
      'category',
      entry.category!.accountName!,
    );
    await CommonTest.enterText(tester, 'description', entry.description);
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
  }

  /// change the amount of the newest entry (row 0)
  static Future<void> updateEntry(WidgetTester tester) async {
    await _openRow(tester, 0);
    final updated = entries.last.copyWith(
      amount: Decimal.parse('99.99'),
      description: 'Coworking day pass (corrected)',
    );
    await _enterEntry(tester, updated);
    entries[entries.length - 1] = updated;
    expect(CommonTest.getTextField('name0'), updated.description);
    expect(CommonTest.getTextField('amount0'), contains('99.99'));
  }

  static Future<void> deleteEntry(WidgetTester tester) async {
    final count = CommonTest.getWidgetCountByKey(tester, 'cashBookItem');
    await _openRow(tester, 0);
    await CommonTest.tapByKey(tester, 'delete');
    await CommonTest.tapByKey(tester, 'continue', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    expect(CommonTest.getWidgetCountByKey(tester, 'cashBookItem'), count - 1);
    entries.removeLast();
  }

  static Future<void> filterAndSearch(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'filterIn', seconds: CommonTest.waitTime);
    expect(
      CommonTest.getWidgetCountByKey(tester, 'cashBookItem'),
      entries.where((e) => e.isIncome).length,
    );
    await CommonTest.tapByKey(
      tester,
      'filterAll',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.doNewSearch(tester, searchString: entries[0].description);
    await CommonTest.checkWidgetKey(tester, 'CashBookDialog');
    expect(CommonTest.getTextFormField('description'), entries[0].description);
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> checkProfitLoss(WidgetTester tester) async {
    Decimal sum(bool income) => entries
        .where((e) => e.isIncome == income)
        .fold(Decimal.zero, (t, e) => t + e.amount!);
    await selectProfitLoss(tester);
    await CommonTest.waitForKey(tester, 'netProfit');
    expect(CommonTest.getTextField('incomeTotal'), _money(sum(true)));
    expect(CommonTest.getTextField('expenseTotal'), _money(sum(false)));
    expect(
      CommonTest.getTextField('netProfit'),
      _money(sum(true) - sum(false)),
    );
  }

  static String _money(Decimal value) => value.currency(currencyId: 'USD');

  static Future<void> _openRow(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(
      tester,
      'name$index',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.checkWidgetKey(tester, 'CashBookDialog');
  }
}
