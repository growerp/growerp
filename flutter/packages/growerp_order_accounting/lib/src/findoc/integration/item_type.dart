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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

class ItemTypeTest {
  static Future<void> selectItemType(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbAccounting', 'AcctDashBoard');
    await CommonTest.selectOption(tester, 'acctSetup', 'ItemTypeListForm', '2');
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
      WidgetTester tester, List<ItemType> itemTypes,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    if (showAll(tester) == false) {
      // switch to show all item types
      await CommonTest.tapByKey(tester, 'switchShow');
    }
    await enterItemTypeData(tester, itemTypes);
    await PersistFunctions.persistTest(test.copyWith(itemTypes: itemTypes));
    if (check) {
      await PersistFunctions.persistTest(
          test.copyWith(itemTypes: await checkItemType(tester, itemTypes)));
    }
  }

  static Future<void> enterItemTypeData(
      WidgetTester tester, List<ItemType> itemTypes) async {
    for (ItemType itemType in itemTypes) {
      await CommonTest.doSearch(tester,
          searchString: "${itemType.itemTypeName} ${itemType.direction}");
      await CommonTest.enterDropDownSearch(
          tester, 'glAccount0', itemType.accountCode);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<ItemType>> checkItemType(
      WidgetTester tester, List<ItemType> itemTypes) async {
    List<ItemType> newItemTypes = [];
    for (ItemType itemType in itemTypes) {
      await CommonTest.doSearch(tester,
          searchString: "${itemType.itemTypeName} ${itemType.direction}");
      expect(CommonTest.getTextField('name0'),
          contains("${itemType.itemTypeName} ${itemType.direction}"));
      expect(CommonTest.getDropdownSearch('glAccount0'),
          contains(itemType.accountCode));
      expect(CommonTest.getDropdownSearch('glAccount0'),
          contains(itemType.accountName));
      newItemTypes.add(itemType);
    }
    return newItemTypes;
  }
}
