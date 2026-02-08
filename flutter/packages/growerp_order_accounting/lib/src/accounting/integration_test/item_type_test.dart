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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:growerp_order_accounting/src/accounting/accounting.dart';

class ItemTypeTest {
  static Future<void> selectItemType(WidgetTester tester) async {
    // Navigate to accounting dashboard first
    await CommonTest.selectOption(tester, '/accounting', 'AcctDashBoard');
    // Then navigate to setup for item types
    await CommonTest.selectOption(
      tester,
      '/accounting/setup/item-types',
      'ItemTypeList',
    );
  }

  static bool showAll(WidgetTester tester) {
    try {
      expect(find.text('All'), findsOneWidget);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteAllItemTypes(WidgetTester tester) async {
    if (showAll(tester) == true) {
      // switch to show used only
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    while (tester.any(find.byKey(const Key('delete0')))) {
      await CommonTest.tapByKey(tester, 'delete0', seconds: 2);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<void> addItemTypes(
    WidgetTester tester,
    List<ItemType> itemTypes, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (showAll(tester) == false) {
      // switch to show all item types
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    await enterItemTypeData(tester, itemTypes);
    await PersistFunctions.persistTest(test.copyWith(itemTypes: itemTypes));
    if (check) {
      await PersistFunctions.persistTest(
        test.copyWith(itemTypes: await checkItemType(tester, itemTypes)),
      );
    }
  }

  static Future<void> enterItemTypeData(
    WidgetTester tester,
    List<ItemType> itemTypes,
  ) async {
    for (ItemType itemType in itemTypes) {
      await CommonTest.enterText(
        tester,
        'searchField',
        '${itemType.itemTypeName} ${itemType.direction}',
      );
      // Wait for both search results and GlAccountBloc to load
      final autoKey = Key(
        'glAccount_${itemType.itemTypeName}_${itemType.direction}',
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        if (tester.any(find.byKey(autoKey))) break;
      }
      // Directly fire the bloc event to update the item type with the GL account
      // (Autocomplete dropdown interaction is unreliable in integration tests)
      final context = tester.element(find.byKey(autoKey));
      final glAccountBloc = context.read<GlAccountBloc>();
      final finDocBloc = context.read<FinDocBloc>();
      final matchingAccount = glAccountBloc.state.glAccounts.firstWhere(
        (gl) => gl.accountCode == itemType.accountCode,
        orElse: () => GlAccount(accountCode: itemType.accountCode),
      );
      finDocBloc.add(
        FinDocUpdateItemType(
          itemType: itemType.copyWith(
            accountCode: matchingAccount.accountCode ?? itemType.accountCode,
            accountName: matchingAccount.accountName ?? '',
          ),
          update: true,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<ItemType>> checkItemType(
    WidgetTester tester,
    List<ItemType> itemTypes,
  ) async {
    List<ItemType> newItemTypes = [];
    for (ItemType itemType in itemTypes) {
      await CommonTest.enterText(
        tester,
        'searchField',
        '${itemType.itemTypeName} ${itemType.direction}',
      );
      // Wait for search results and GL accounts to load
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        if (tester.any(find.byKey(const Key('name0')))) break;
      }
      expect(CommonTest.getTextField('name0'), contains(itemType.itemTypeName));
      expect(
        CommonTest.getTextFormField(
          'glAccountField_${itemType.itemTypeName}_${itemType.direction}',
        ),
        contains(itemType.accountCode),
      );
      newItemTypes.add(itemType);
    }
    return newItemTypes;
  }
}
