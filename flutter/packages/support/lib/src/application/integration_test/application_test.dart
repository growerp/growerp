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

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ApplicationTest {
  static Future<void> selectApplication(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'Applications', 'Applications');
    await tester.pumpAndSettle();
  }

  static Future<void> addApplication(
    WidgetTester tester, {
    required String applicationId,
    required String version,
    required String backendUrl,
  }) async {
    await tester.tap(find.byKey(const Key('addNew')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('Id')), applicationId);
    await tester.enterText(find.byKey(const Key('version')), version);
    await tester.enterText(find.byKey(const Key('backendUrl')), backendUrl);
    await tester.tap(find.byKey(const Key('update')));
    await tester.pumpAndSettle();
  }

  static Future<void> updateApplication(
    WidgetTester tester, {
    required String applicationId,
    required String version,
    required String backendUrl,
  }) async {
    await tester.tap(find.text(applicationId).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('version')), version);
    await tester.enterText(find.byKey(const Key('backendUrl')), backendUrl);
    await tester.tap(find.byKey(const Key('update')));
    await tester.pumpAndSettle();
  }

  static Future<void> deleteApplication(
    WidgetTester tester, {
    required String applicationId,
  }) async {
    await tester.tap(find.descendant(
        of: find.ancestor(
            of: find.text(applicationId), matching: find.byType(TableViewCell)),
        matching: find.byIcon(Icons.delete_forever)));
    await tester.pumpAndSettle();
  }
}
