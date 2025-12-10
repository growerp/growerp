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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

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
    int seq = test.sequence;
    if (test.assets.isEmpty) {
      // not yet created
      test = test.copyWith(assets: assets);
      await enterAssetData(tester, assets);
      await PersistFunctions.persistTest(test);
    }
    if (check && test.assets[0].assetId.isEmpty) {
      await PersistFunctions.persistTest(
        test.copyWith(
          assets: await checkAssetDetail(tester, test.assets),
          sequence: seq,
        ),
      );
    }
  }

  static Future<void> enterAssetData(
    WidgetTester tester,
    List<Asset> assets,
  ) async {
    for (Asset asset in assets) {
      if (asset.assetId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: asset.assetId);
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          asset.pseudoId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'AssetDialog');
      await CommonTest.tapByKey(
        tester,
        'name',
      ); // required because keyboard come up
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
      // select product
      await CommonTest.enterDropDownSearch(
        tester,
        'productDropDown',
        asset.product!.productName!,
      );
      // select location if present
      if (asset.location != null && asset.location!.locationName != null) {
        await CommonTest.enterDropDownSearch(
          tester,
          'locationDropDown',
          asset.location!.locationName!,
        );
      }
      await CommonTest.dragUntil(tester, key: 'update');
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Asset>> checkAssetDetail(
    WidgetTester tester,
    List<Asset> assets,
  ) async {
    List<Asset> newAssets = [];
    for (Asset asset in assets) {
      await CommonTest.doNewSearch(
        tester,
        searchString: asset.assetName!,
        seconds: CommonTest.waitTime,
      );
      // detail dialog should be open
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
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newAssets.add(asset.copyWith(assetId: id, pseudoId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newAssets;
  }

  static Future<void> deleteLastAsset(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.assets.length;
    // find the asset count from the UI
    // The delete button in AssetList uses the statusId toggle pattern
    // (Available/Deactivated), so we tap delete to deactivate the last asset
    await CommonTest.tapByKey(
      tester,
      'delete${count - 1}',
      seconds: CommonTest.waitTime,
    );
    // Wait for update to complete
    await CommonTest.waitForSnackbarToGo(tester);
    // Check that the asset is now deactivated (status shows 'N')
    expect(CommonTest.getTextField('status${count - 1}'), equals('N'));
    await PersistFunctions.persistTest(
      test.copyWith(assets: test.assets.sublist(0, test.assets.length - 1)),
    );
  }

  static Future<void> updateAssets(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.assets[0].assetName!.endsWith('u')) return;
    List<Asset> updAssets = [];
    for (Asset asset in test.assets) {
      updAssets.add(asset.copyWith(assetName: '${asset.assetName}u'));
    }
    await enterAssetData(tester, updAssets);
    await checkAssetDetail(tester, updAssets);
    await PersistFunctions.persistTest(test.copyWith(assets: updAssets));
  }
}
