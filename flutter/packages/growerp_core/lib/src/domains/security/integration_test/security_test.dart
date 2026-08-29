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

/// Test helpers for the Organization -> Security screen.
///
/// The grid is keyed by row index rather than menuItemId on purpose: the first
/// save clones the seed menu for the organization, which changes every id.
class SecurityTest {
  /// Open Organization -> Security. [route] is the organization menu route of
  /// the app under test ('/companies' in both the admin app and the core
  /// example), [tabLabel] the tab title as rendered.
  static Future<void> selectSecurity(
    WidgetTester tester, {
    String route = '/companies',
    String tabLabel = 'Security',
  }) async {
    if (find
        .byKey(const Key('HomeFormAuth'))
        .toString()
        .startsWith('Found 0 widgets with key')) {
      await CommonTest.gotoMainMenu(tester);
    }
    await CommonTest.selectOption(tester, route, 'securityList', tabLabel);
  }

  /// The grid lists every screen of the app, including ones the admin's own
  /// group cannot use, so on a seeded backend it is never empty.
  static Future<void> checkGrid(WidgetTester tester) async {
    expect(
      find.byKey(const Key('securityItem0')),
      findsOneWidget,
      reason: 'the security grid should list at least one screen',
    );
  }

  /// Current access shown for [group] on the row at [index]: 'none', 'view' or
  /// 'write'.
  static String accessOfRow(WidgetTester tester, int index, String group) {
    final chip = find.byKey(Key('cell-$index-$group'));
    expect(chip, findsOneWidget, reason: 'no cell for row $index / $group');
    return tester.widget<AccessChip>(chip).label;
  }

  static Future<void> checkAccess(
    WidgetTester tester,
    int index,
    String group,
    String expected,
  ) async {
    expect(
      accessOfRow(tester, index, group),
      expected,
      reason: 'row $index should be $expected for $group',
    );
  }

  /// Open the row at [index], set [group] to [level] ('none'/'view'/'write')
  /// and save.
  static Future<void> setAccess(
    WidgetTester tester,
    int index,
    String group,
    String level,
  ) async {
    await CommonTest.tapByKey(tester, 'securityItem$index');
    expect(
      find.byKey(const Key('SecurityDialog')),
      findsOneWidget,
      reason: 'security dialog did not open for row $index',
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(Key('access-$group')),
        matching: find.text(level),
      ),
    );
    await tester.pumpAndSettle();

    await CommonTest.tapByKey(tester, 'update');
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(
      find.byKey(const Key('SecurityDialog')),
      findsNothing,
      reason: 'security dialog should close after a successful save',
    );
  }

  /// The system group is not the organization's to grant, so the grid must not
  /// offer it - server side set#MenuItemGroups rejects it as well.
  static Future<void> checkNoSystemColumn(WidgetTester tester) async {
    expect(
      find.byKey(const Key('cell-0-system')),
      findsNothing,
      reason: 'the grid must not offer the system group',
    );
  }
}
