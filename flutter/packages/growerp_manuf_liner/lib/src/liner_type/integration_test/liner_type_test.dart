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
