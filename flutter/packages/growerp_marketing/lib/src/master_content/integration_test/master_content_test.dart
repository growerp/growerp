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

class MasterContentTest {
  static Future<void> selectMasterContent(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/masterContent',
      'MasterContentList',
      null,
    );
  }

  static Future<void> addMasterContent(
    WidgetTester tester,
    List<MasterContent> masterContents,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(
      test.copyWith(masterContents: masterContents),
    );
    await enterMasterContentData(tester);
  }

  static Future<void> updateMasterContent(
    WidgetTester tester,
    List<MasterContent> newMasterContents,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<MasterContent> updated = [];
    for (int x = 0; x < newMasterContents.length; x++) {
      updated.add(
        newMasterContents[x].copyWith(
          masterContentId: old.masterContents[x].masterContentId,
          pseudoId: old.masterContents[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(old.copyWith(masterContents: updated));
    await enterMasterContentData(tester);
  }

  static Future<void> deleteMasterContent(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.masterContents.length;
    expect(
      find.byKey(const Key('masterContentItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(tester, 'delete0', seconds: CommonTest.waitTime);
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm0',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('masterContentItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(masterContents: test.masterContents.sublist(1, count)),
    );
  }

  static Future<void> doMasterContentSearch(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.doNewSearch(tester, searchString: searchString);
  }

  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(const Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterMasterContentData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<MasterContent> newMasterContents = [];

    for (MasterContent mc in test.masterContents) {
      if (mc.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'addNewMasterContent');
      } else {
        await doMasterContentSearch(tester, searchString: mc.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(mc.pseudoId!),
          true,
        );
      }

      final expectedKey = mc.pseudoId == null
          ? 'MasterContentDetailnull'
          : 'MasterContentDetail${mc.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      await CommonTest.selectDropDown(tester, 'contentType', mc.contentType);
      await CommonTest.selectDropDown(tester, 'pnpType', mc.pnpType);
      await CommonTest.selectDropDown(tester, 'status', mc.status);

      if (mc.title != null) {
        await CommonTest.enterText(tester, 'title', mc.title!);
      }
      if (mc.body != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'body',
          listViewName: 'masterContentDetailListView',
        );
        await CommonTest.enterText(tester, 'body', mc.body!);
      }
      if (mc.callToAction != null) {
        await CommonTest.enterText(tester, 'callToAction', mc.callToAction!);
      }

      await CommonTest.dragUntil(
        tester,
        key: 'masterContentDetailSave',
        listViewName: 'masterContentDetailListView',
      );
      await CommonTest.tapByKey(
        tester,
        'masterContentDetailSave',
        seconds: CommonTest.waitTime,
      );

      // Get allocated ID for new pieces
      if (mc.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'title0', seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        mc = mc.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newMasterContents.add(mc);
    }

    await clearSearch(tester);
    await PersistFunctions.persistTest(
      test.copyWith(masterContents: newMasterContents),
    );
  }

  static Future<void> checkMasterContent(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (MasterContent mc in test.masterContents) {
      await doMasterContentSearch(tester, searchString: mc.pseudoId!);

      expect(
        find.byKey(Key('MasterContentDetail${mc.pseudoId}')),
        findsOneWidget,
      );

      if (mc.title != null) {
        expect(CommonTest.getTextFormField('title'), equals(mc.title));
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }
}
