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
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class SocialPostTest {
  static Future<void> selectSocialPosts(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/socialPosts',
      'SocialPostList',
      null,
    );
  }

  static Future<void> addSocialPosts(
    WidgetTester tester,
    List<SocialPost> socialPosts,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(socialPosts: socialPosts));
    await enterSocialPostData(tester);
  }

  static Future<void> updateSocialPosts(
    WidgetTester tester,
    List<SocialPost> newSocialPosts,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<SocialPost> updatedSocialPosts = [];
    for (int x = 0; x < newSocialPosts.length; x++) {
      updatedSocialPosts.add(
        newSocialPosts[x].copyWith(
          postId: old.socialPosts[x].postId,
          pseudoId: old.socialPosts[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
        old.copyWith(socialPosts: updatedSocialPosts));
    await enterSocialPostData(tester);
  }

  static Future<void> deleteSocialPosts(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.socialPosts.length;
    expect(
      find.byKey(const Key('socialPostItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete0',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm0',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('socialPostItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(socialPosts: test.socialPosts.sublist(1, count)),
    );
  }

  /// Search for social posts using ListFilterBar and tap the first result
  static Future<void> doSocialPostSearch(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.tapByKey(tester, 'headline0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Clear the search field to show all items
  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterSocialPostData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<SocialPost> newSocialPosts = [];

    for (SocialPost socialPost in test.socialPosts) {
      if (socialPost.pseudoId == null) {
        // Add new social post
        await CommonTest.tapByKey(tester, 'addNewSocialPost');
      } else {
        // Update existing social post - use custom search
        await doSocialPostSearch(tester, searchString: socialPost.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(socialPost.pseudoId!),
          true,
        );
      }

      // Check for the detail screen (key varies based on pseudoId)
      final expectedKey = socialPost.pseudoId == null
          ? 'SocialPostDetailnull'
          : 'SocialPostDetail${socialPost.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      // Select type from dropdown
      await CommonTest.selectDropDown(tester, 'type', socialPost.type);

      // Select plan from dropdown (mandatory)
      if (test.contentPlans.isNotEmpty) {
        await CommonTest.selectDropDown(
            tester, 'planId', test.contentPlans[0].pseudoId!);
      }

      // Enter headline
      if (socialPost.headline != null) {
        await CommonTest.enterText(tester, 'headline', socialPost.headline!);
      }

      // Enter draft content
      if (socialPost.draftContent != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'draftContent',
          listViewName: 'socialPostDetailListView',
        );
        await CommonTest.enterText(
            tester, 'draftContent', socialPost.draftContent!);
      }

      // Select status from dropdown
      await CommonTest.dragUntil(
        tester,
        key: 'status',
        listViewName: 'socialPostDetailListView',
      );
      await CommonTest.selectDropDown(tester, 'status', socialPost.status);

      // Save the social post
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

      // Get allocated ID for new social posts
      if (socialPost.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'headline0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        socialPost = socialPost.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newSocialPosts.add(socialPost);
    }

    await clearSearch(tester);
    await PersistFunctions.persistTest(
        test.copyWith(socialPosts: newSocialPosts));
  }

  static Future<void> checkSocialPosts(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (SocialPost socialPost in test.socialPosts) {
      await doSocialPostSearch(tester, searchString: socialPost.pseudoId!);

      // Check detail - the dialog key is SocialPostDetail${pseudoId}
      expect(find.byKey(Key('SocialPostDetail${socialPost.pseudoId}')),
          findsOneWidget);

      if (socialPost.headline != null) {
        expect(CommonTest.getTextFormField('headline'),
            equals(socialPost.headline));
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }
}
