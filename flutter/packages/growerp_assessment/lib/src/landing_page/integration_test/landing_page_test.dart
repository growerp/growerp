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

class LandingPageTest {
  static Future<void> selectLandingPages(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/landingPages',
      'LandingPageList',
      null,
    );
  }

  static Future<void> addLandingPages(
    WidgetTester tester,
    List<LandingPage> landingPages,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
        test.copyWith(landingPages: landingPages));
    await enterLandingPageData(tester);
  }

  static Future<void> updateLandingPages(
    WidgetTester tester,
    List<LandingPage> newLandingPages,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<LandingPage> updatedPages = [];
    for (int x = 0; x < newLandingPages.length; x++) {
      updatedPages.add(
        newLandingPages[x].copyWith(
          landingPageId: old.landingPages[x].landingPageId,
          pseudoId: old.landingPages[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(
        old.copyWith(landingPages: updatedPages));
    await enterLandingPageData(tester);
  }

  static Future<void> deleteLandingPages(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.landingPages.length;
    expect(
      find.byKey(const Key('landingPageItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm${count - 1}',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('landingPageItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(landingPages: test.landingPages.sublist(0, count - 1)),
    );
  }

  static Future<void> enterLandingPageData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<LandingPage> newPages = [];

    for (LandingPage page in test.landingPages) {
      if (page.pseudoId == null) {
        // Add new landing page
        await CommonTest.tapByKey(tester, 'addNewLandingPage');
      } else {
        // Update existing landing page
        await CommonTest.doNewSearch(tester, searchString: page.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(page.pseudoId!),
          true,
        );
      }

      // Wait for the detail screen dialog to appear
      await tester.pumpAndSettle();

      // Check for the detail screen (key varies based on pseudoId)
      final expectedKey = page.pseudoId == null
          ? 'LandingPageDetailnull'
          : 'LandingPageDetail${page.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      // Enter basic info
      await CommonTest.enterText(tester, 'title', page.title);
      await CommonTest.enterDropDown(tester, 'status', page.status);

      if (page.hookType != null) {
        await CommonTest.enterDropDown(tester, 'hookType', page.hookType!);
      }

      if (page.privacyPolicyUrl != null) {
        await CommonTest.enterText(
            tester, 'privacyPolicyUrl', page.privacyPolicyUrl!);
      }

      if (page.headline != null) {
        await CommonTest.enterText(tester, 'headline', page.headline!);
      }

      if (page.subheading != null) {
        await CommonTest.enterText(tester, 'subheading', page.subheading!);
      }

      if (page.ctaActionType != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'ctaActionType',
          listViewName: 'landingPageDialogListView',
        );
        await CommonTest.enterDropDown(
            tester, 'ctaActionType', page.ctaActionType!);
      }

      // Save the landing page
      await CommonTest.dragUntil(
        tester,
        key: 'landingPageDetailSave',
        listViewName: 'landingPageDialogListView',
      );
      await CommonTest.tapByKey(
        tester,
        'landingPageDetailSave',
        seconds: CommonTest.waitTime,
      );

      // Get allocated ID for new pages
      if (page.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'item0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        page = page.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newPages.add(page);
    }

    await PersistFunctions.persistTest(test.copyWith(landingPages: newPages));
  }

  static Future<void> checkLandingPages(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (LandingPage page in test.landingPages) {
      await CommonTest.doNewSearch(tester, searchString: page.pseudoId!);

      // Check detail - the dialog key is LandingPageDetail${pseudoId}
      expect(
          find.byKey(Key('LandingPageDetail${page.pseudoId}')), findsOneWidget);
      expect(CommonTest.getTextFormField('title'), equals(page.title));

      if (page.headline != null) {
        expect(
          CommonTest.getTextFormField('headline'),
          equals(page.headline!),
        );
      }

      if (page.subheading != null) {
        expect(
          CommonTest.getTextFormField('subheading'),
          equals(page.subheading!),
        );
      }

      if (page.hookType != null) {
        expect(
          CommonTest.getDropdown('hookType'),
          equals(page.hookType!),
        );
      }

      if (page.ctaActionType != null) {
        expect(
          CommonTest.getDropdown('ctaActionType'),
          equals(page.ctaActionType!),
        );
      }

      expect(
        CommonTest.getDropdown('status'),
        equals(page.status),
      );

      if (page.privacyPolicyUrl != null) {
        expect(
          CommonTest.getTextFormField('privacyPolicyUrl'),
          equals(page.privacyPolicyUrl!),
        );
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
  }
}
