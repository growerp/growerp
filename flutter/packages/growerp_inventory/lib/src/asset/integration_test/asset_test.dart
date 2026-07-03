/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

/// Asset integration-test helpers, following the same add/update/check/delete
/// pattern as [UserTest]/[CompanyTest]: records are always located by their
/// allocated `pseudoId` (the keyed `id$row` cell), and the allocated id of a
/// freshly added record is read back by searching for a known field value
/// rather than blindly tapping row 0.
class AssetTest {
  static Future<void> selectAssets(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/assets', 'AssetList');
  }

  static Future<void> addAssets(
    WidgetTester tester,
    List<Asset> assets, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    if (test.assets.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(assets: assets));
    }
    await enterAssetData(tester);
    if (check) await checkAssets(tester);
  }

  static Future<void> updateAssets(
    WidgetTester tester,
    List<Asset> newAssets,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // carry the allocated ids of the existing records into the new data
    for (int i = 0; i < newAssets.length; i++) {
      newAssets[i] = newAssets[i].copyWith(
        assetId: old.assets[i].assetId,
        pseudoId: old.assets[i].pseudoId,
      );
    }
    await PersistFunctions.persistTest(old.copyWith(assets: newAssets));
    await enterAssetData(tester);
    await checkAssets(tester);
  }

  static Future<void> enterAssetData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Asset> newAssets = [];
    for (Asset asset in test.assets) {
      if (asset.pseudoId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: asset.pseudoId);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          asset.pseudoId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'AssetDialog');
      await CommonTest.enterText(tester, 'name', asset.assetName!);
      await CommonTest.enterText(
        tester,
        'quantityOnHand',
        asset.quantityOnHand.toString(),
      );
      await CommonTest.enterText(
        tester,
        'availableToPromise',
        asset.availableToPromise.toString(),
      );
      await CommonTest.enterText(
        tester,
        'acquireCost',
        asset.acquireCost.toString(),
      );
      await CommonTest.enterDropDownSearch(
        tester,
        'productDropDown',
        asset.product!.productName!,
      );
      if (asset.location?.locationName != null) {
        await CommonTest.enterDropDownSearch(
          tester,
          'locationDropDown',
          asset.location!.locationName!,
        );
      }
      await CommonTest.dragUntil(tester, key: 'update');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
      // let the dialog's dismiss animation finish before the next search, so
      // its closing route barrier can't absorb the next row tap (which would
      // leave the previous record's dialog on screen).
      await tester.pumpAndSettle();
      // for a new record read back the allocated id; find the row by assetName
      // (the list filters on it) instead of position.
      if (asset.pseudoId.isEmpty) {
        await CommonTest.doNewSearch(tester, searchString: asset.assetName!);
        final id = CommonTest.getTextField('topHeader').split('#')[1];
        asset = asset.copyWith(assetId: id, pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
        await CommonTest.enterText(tester, 'searchField', '');
      }
      newAssets.add(asset);
    }
    await PersistFunctions.persistTest(test.copyWith(assets: newAssets));
  }

  static Future<void> checkAssets(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);
    for (Asset asset in test.assets) {
      await CommonTest.doNewSearch(tester, searchString: asset.pseudoId);
      expect(find.byKey(const Key('AssetDialog')), findsOneWidget);
      expect(CommonTest.getTextFormField('name'), equals(asset.assetName!));
      expect(
        CommonTest.getTextFormField('quantityOnHand'),
        equals(asset.quantityOnHand.toString()),
      );
      expect(
        CommonTest.getTextFormField('availableToPromise'),
        equals(asset.availableToPromise.toString()),
      );
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  static Future<void> deleteLastAsset(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.assets.length;
    // Clear any active search filter so all assets are displayed
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    // The delete button in AssetList uses the statusId toggle pattern
    // (Available/Deactivated), so we tap delete to deactivate the last asset.
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.waitForSnackbarToGo(tester);
    // Check that the asset is now deactivated: the status chip shows 'N' on
    // the phone layout and 'No' on the desktop layout.
    final statusFinder = find.byKey(Key('status${count - 1}'));
    expect(statusFinder, findsOneWidget);
    final statusChip = statusFinder.evaluate().single.widget as StatusChip;
    expect(statusChip.label, anyOf(equals('N'), equals('No')));
    await PersistFunctions.persistTest(
      test.copyWith(assets: test.assets.sublist(0, test.assets.length - 1)),
    );
  }
}
