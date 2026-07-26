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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:growerp_order_accounting/src/accounting/accounting.dart';

class ItemTypeTest {
  static Future<void> selectItemType(WidgetTester tester) async {
    // Go to main menu first to ensure clean navigation state
    await CommonTest.gotoMainMenu(tester);
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
