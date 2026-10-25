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

import '../../get_marketing_widgets.dart';

class ContentCalendarTest {
  /// The posts are in the in-app calendar, opened from the app bar; the
  /// example app registers no widgets, so the post dialog is registered here.
  static Future<void> selectContentCalendar(WidgetTester tester) async {
    WidgetRegistry.registerAllWithMetadata(getMarketingWidgetsWithMetadata());
    await CalendarTest.openCalendar(tester);
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
  static Future<void> checkPostOnDay(WidgetTester tester, DateTime date) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    SocialPost post = test.socialPosts.first;

    expect(
      find.byKey(
        Key('calendarDay_${CalendarTest.dayKey(date)}'),
        skipOffstage: false,
      ),
      findsOneWidget,
      reason: 'day cell for ${CalendarTest.dayKey(date)} not on the calendar',
    );
    await CalendarTest.tapItem(tester, post.headline!);
    expect(find.byKey(Key('SocialPostDetail${post.pseudoId}')), findsOneWidget);
    await CalendarTest.closeDialog(tester);
    await CalendarTest.closeDialog(tester);
  }
}
