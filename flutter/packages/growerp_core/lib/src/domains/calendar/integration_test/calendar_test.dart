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

/// The in-app calendar, opened from the app bar.
class CalendarTest {
  static Future<void> openCalendar(WidgetTester tester) async {
    await CommonTest.tapByKey(
      tester,
      'calendarButton',
      seconds: CommonTest.waitTime,
    );
    expect(find.byKey(const Key('appCalendar')), findsOneWidget);
  }

  /// Closes the topmost dialog: an item dialog over the calendar, or the
  /// calendar itself.
  static Future<void> closeDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('cancel')).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// The item whose label contains [text] is on the calendar; tapping it
  /// opens its dialog.
  static Future<void> tapItem(WidgetTester tester, String text) async {
    final item = find.descendant(
      of: find.byKey(const Key('appCalendar')),
      matching: find.textContaining(text),
    );
    expect(item, findsWidgets, reason: "'$text' is not on the calendar");
    await tester.tap(item.first);
    await tester.pumpAndSettle(Duration(seconds: CommonTest.waitTime));
  }

  /// Same yyyyMMdd shape the calendar builds its day-cell keys from.
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}
