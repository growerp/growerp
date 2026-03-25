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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class LinerTypeTest {
  static Future<void> selectLinerTypes(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/liner/linerType',
      'LinerTypeList',
    );
  }

  static Future<void> addLinerTypes(
    WidgetTester tester,
    List<LinerType> linerTypes,
  ) async {
    await enterLinerTypeData(tester, linerTypes);
    // Backend returns newest-first; reverse the input list to match display order.
    await checkLinerTypes(tester, linerTypes.reversed.toList());
  }

  static Future<void> enterLinerTypeData(
    WidgetTester tester,
    List<LinerType> linerTypes,
  ) async {
    for (LinerType linerType in linerTypes) {
      if (linerType.linerTypeId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: linerType.linerName ?? '',
        );
        await CommonTest.tapByKey(tester, 'item0');
      }
      if (linerType.linerName != null) {
        await CommonTest.enterText(tester, 'linerName', linerType.linerName!);
      }
      if (linerType.widthIncrement != null) {
        await CommonTest.enterText(
            tester, 'widthIncrement', linerType.widthIncrement.toString());
      }
      if (linerType.linerWeight != null) {
        await CommonTest.enterText(
            tester, 'linerWeight', linerType.linerWeight.toString());
      }
      if (linerType.rollStockWidth != null) {
        await CommonTest.enterText(
            tester, 'rollStockWidth', linerType.rollStockWidth.toString());
      }
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  static Future<void> checkLinerTypes(
    WidgetTester tester,
    List<LinerType> linerTypes,
  ) async {
    for (int i = 0; i < linerTypes.length; i++) {
      await CommonTest.waitForKey(tester, 'linerName$i');
      if (linerTypes[i].linerName != null) {
        expect(
          CommonTest.getTextField('linerName$i'),
          contains(linerTypes[i].linerName!),
          reason: 'LinerType $i should display expected name',
        );
      }
    }
  }

  static Future<void> deleteLinerType(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'delete$index');
    await CommonTest.tapByKey(tester, 'continue');
  }

  static Future<void> openLinerType(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'LinerTypeDialog');
  }
}
