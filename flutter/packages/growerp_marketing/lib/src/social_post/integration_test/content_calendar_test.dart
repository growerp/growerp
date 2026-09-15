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
import 'package:growerp_models/growerp_models.dart';

class ContentCalendarTest {
  static Future<void> selectContentCalendar(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/contentCalendar',
      'contentCalendar',
      null,
    );
  }

  /// Puts the first saved post on [date] through the social post detail
  /// dialog, so the calendar has something to show. Must be called with the
  /// social post list on screen.
  static Future<void> scheduleFirstPost(
    WidgetTester tester,
    DateTime date,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    SocialPost post = test.socialPosts.first;

    await CommonTest.doNewSearch(tester, searchString: post.pseudoId!);
    expect(find.byKey(Key('SocialPostDetail${post.pseudoId}')), findsOneWidget);

    // the create just before this leaves a success snackbar over the bottom of
    // the dialog, which swallows the tap on the save button
    await CommonTest.waitForSnackbarToGo(tester);

    await CommonTest.dragUntil(
      tester,
      key: 'scheduledDate',
      listViewName: 'socialPostDetailListView',
    );
    // usDate: the picker's input field parses in the app locale (en), so an
    // ISO string is rejected and the OK button silently does nothing
    await CommonTest.enterDate(tester, 'scheduledDate', date, usDate: true);

    await CommonTest.dragUntil(
      tester,
      key: 'socialPostDetailSave',
      listViewName: 'socialPostDetailListView',
    );
    await CommonTest.tapByKey(
      tester,
      'socialPostDetailSave',
      seconds: CommonTest.waitTime,
    );

    await PersistFunctions.persistTest(
      test.copyWith(
        socialPosts: [
          post.copyWith(scheduledDate: date),
          ...test.socialPosts.sublist(1),
        ],
      ),
    );
  }

  /// The scheduled post shows in its day cell, and tapping it opens the same
  /// post's detail dialog.
  static Future<void> checkPostOnDay(
    WidgetTester tester,
    DateTime date,
  ) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    SocialPost post = test.socialPosts.first;

    expect(
      find.byKey(Key('calendarDay_${dayKey(date)}'), skipOffstage: false),
      findsOneWidget,
      reason: 'day cell for ${dayKey(date)} not on the calendar',
    );
    expect(
      find.byKey(const Key('calendarPost0'), skipOffstage: false),
      findsOneWidget,
      reason: 'the scheduled post is not shown on the calendar',
    );

    await CommonTest.tapByKey(
      tester,
      'calendarPost0',
      seconds: CommonTest.waitTime,
    );
    expect(find.byKey(Key('SocialPostDetail${post.pseudoId}')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'cancel');
  }

  /// Same yyyyMMdd shape the calendar builds its day-cell keys from.
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}
