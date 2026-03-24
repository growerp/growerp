/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class BomTest {
  static Future<void> selectBom(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/manufacturing/bom', 'BomList');
  }

  /// Creates a new BOM from the summary list.
  ///
  /// Taps the FAB, fills the assembly product fields ([pseudoId] optional,
  /// [productName] required), then adds all [components] one by one.
  /// At least one component is required.
  ///
  /// After this call the BOM dialog is still open with all components visible.
  static Future<void> createBomWithComponents(
    WidgetTester tester, {
    required String productName,
    String pseudoId = '',
    required List<BomItem> components,
  }) async {
    assert(components.isNotEmpty, 'At least one component is required');

    await CommonTest.tapByKey(tester, 'addNew');
    await CommonTest.waitForKey(tester, 'BomDialog');

    if (pseudoId.isNotEmpty) {
      await CommonTest.enterText(tester, 'pseudoId', pseudoId);
    }
    await CommonTest.enterText(tester, 'productName', productName);

    // First component triggers product creation + BOM item creation
    final first = components.first;
    await CommonTest.enterAutocompleteValue(
      tester,
      'componentId0',
      first.componentPseudoId,
    );
    if (first.quantity != null) {
      await CommonTest.enterText(
        tester,
        'quantity',
        first.quantity.toString(),
      );
    }
    await CommonTest.tapByKey(tester, 'addComponent'); // "Create BOM"
    await CommonTest.waitForKey(tester, 'componentPseudoId0');

    // Subsequent components — _addFormKey increments after each successful add
    for (int i = 1; i < components.length; i++) {
      final item = components[i];
      await CommonTest.enterAutocompleteValue(
        tester,
        'componentId$i',
        item.componentPseudoId,
      );
      if (item.quantity != null) {
        await CommonTest.enterText(
          tester,
          'quantity',
          item.quantity.toString(),
        );
      }
      await CommonTest.tapByKey(tester, 'addComponent'); // "Add Component"
      await CommonTest.waitForKey(tester, 'componentPseudoId$i');
    }
  }

  /// Opens an existing BOM from the summary list by tapping its row.
  ///
  /// Waits for the BOM dialog to appear before returning.
  static Future<void> openBom(
    WidgetTester tester,
    String productPseudoId,
  ) async {
    for (int i = 0; i < 20; i++) {
      final finder = find.byKey(Key('productPseudoId$i'));
      if (finder.evaluate().isEmpty) break;
      final text = tester.widget<Text>(finder).data;
      if (text == productPseudoId) {
        await CommonTest.tapByKey(tester, 'item$i');
        await CommonTest.waitForKey(tester, 'BomDialog');
        return;
      }
    }
    fail('BOM with pseudoId $productPseudoId not found in summary list');
  }

  /// Verifies that all [bomItems] component pseudoIds appear in the currently
  /// open BOM dialog (order-independent).
  static Future<void> checkBomComponents(
    WidgetTester tester,
    List<BomItem> bomItems,
  ) async {
    final expectedIds = bomItems.map((e) => e.componentPseudoId).toSet();
    final actualIds = <String>{};
    for (int i = 0; i < bomItems.length; i++) {
      await CommonTest.waitForKey(tester, 'componentPseudoId$i');
      actualIds.add(CommonTest.getTextField('componentPseudoId$i'));
    }
    expect(actualIds, expectedIds);
  }

  /// Deletes the component at [index] from the open BOM dialog.
  static Future<void> deleteBomComponent(
    WidgetTester tester,
    int index,
  ) async {
    await CommonTest.tapByKey(tester, 'delete$index');
    await CommonTest.tapByKey(tester, 'continue');
  }
}
