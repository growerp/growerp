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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class LinerPanelTest {
  static Future<void> addLinerPanels(
    WidgetTester tester,
    List<LinerPanel> linerPanels,
  ) async {
    for (LinerPanel linerPanel in linerPanels) {
      await tester.ensureVisible(find.byKey(const Key('addPanel')));
      await tester.pumpAndSettle();
      await CommonTest.tapByKey(tester, 'addPanel');
      if (linerPanel.linerTypeId != null) {
        await CommonTest.tapByKey(tester, 'linerTypeDropdown');
        // select by linerTypeId - assumes dropdown items are already rendered
        await CommonTest.tapByText(tester, linerPanel.linerTypeId!);
      }
      if (linerPanel.panelName != null) {
        await CommonTest.enterText(
            tester, 'panelName', linerPanel.panelName!);
      }
      if (linerPanel.panelWidth != null) {
        await CommonTest.enterText(
            tester, 'panelWidth', linerPanel.panelWidth.toString());
      }
      if (linerPanel.panelLength != null) {
        await CommonTest.enterText(
            tester, 'panelLength', linerPanel.panelLength.toString());
      }
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'qcNum0');
    }
  }

  static Future<void> checkLinerPanels(
    WidgetTester tester,
    int expectedCount,
  ) async {
    for (int i = 0; i < expectedCount; i++) {
      await CommonTest.waitForKey(tester, 'qcNum$i');
      expect(
        CommonTest.getTextField('qcNum$i').isNotEmpty,
        true,
        reason: 'Panel $i should have a QC number',
      );
    }
  }

  static Future<void> deleteLinerPanel(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'delete$index');
    await CommonTest.tapByKey(tester, 'continue');
  }

  static Future<void> checkComputedFields(
    WidgetTester tester,
    int index,
  ) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'LinerPanelDialog');
    await CommonTest.waitForKey(tester, 'panelSqft');
    await CommonTest.waitForKey(tester, 'passes');
    await CommonTest.waitForKey(tester, 'weight');
    await CommonTest.tapByKey(tester, 'cancel');
  }
}
