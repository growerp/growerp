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

// ignore_for_file: depend_on_referenced_packages
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class AssetTest {
  static Future<void> selectAsset(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbInventory', 'AssetList', '1');
  }

  static Future<void> addAssets(WidgetTester tester, List<Asset> assets,
      {bool check = true, String classificationId = 'AppAdmin'}) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence;
    if (test.assets.isEmpty) {
      // not yet created
      test = test.copyWith(assets: assets);
      await enterAssetData(tester, assets, classificationId: classificationId);
      await PersistFunctions.persistTest(test);
    }
    if (check && test.assets[0].assetId.isEmpty) {
      await PersistFunctions.persistTest(test.copyWith(
        assets: await checkAssetDetail(tester, test.assets,
            classificationId: classificationId),
        sequence: seq,
      ));
    }
  }

  static Future<void> enterAssetData(WidgetTester tester, List<Asset> assets,
      {String classificationId = 'AppAdmin'}) async {
    for (Asset asset in assets) {
      if (asset.assetId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: asset.assetId);
        await CommonTest.tapByKey(tester, 'name0');
        expect(
            CommonTest.getTextField('topHeader').split('#')[1], asset.assetId);
      }
      await CommonTest.checkWidgetKey(tester, 'AssetDialog');
      await CommonTest.tapByKey(
          tester, 'name'); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', asset.assetName!);
      if (classificationId == 'AppAdmin') {
        await CommonTest.enterText(
            tester, 'quantityOnHand', asset.quantityOnHand.toString());
        await CommonTest.enterText(
            tester, 'availableToPromise', asset.availableToPromise.toString());
        await CommonTest.enterText(
            tester, 'acquireCost', asset.acquireCost.toString());
      }
      await CommonTest.enterDropDownSearch(
          tester, 'productDropDown', asset.product!.productName!);
      await CommonTest.enterDropDown(tester, 'statusDropDown', asset.statusId!);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Asset>> checkAssetDetail(
      WidgetTester tester, List<Asset> assets,
      {String classificationId = 'AppAdmin'}) async {
    List<Asset> newAssets = [];
    for (Asset asset in assets) {
      await CommonTest.doNewSearch(tester, searchString: asset.assetName!);
      // detail
      expect(find.byKey(const Key('AssetDialog')), findsOneWidget);
      expect(CommonTest.getTextFormField('name'), equals(asset.assetName!));
      if (classificationId == 'AppAdmin') {
        expect(CommonTest.getTextFormField('quantityOnHand'),
            equals(asset.quantityOnHand.toString()));
        expect(CommonTest.getTextFormField('availableToPromise'),
            equals(asset.availableToPromise.toString()));
        expect(CommonTest.getTextFormField('acquireCost'),
            equals(asset.acquireCost.currency(currencyId: '')));
      }
      expect(CommonTest.getDropdownSearch('productDropDown'),
          asset.product!.productName!);
      expect(CommonTest.getDropdown('statusDropDown'), asset.statusId);
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newAssets.add(asset.copyWith(assetId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newAssets;
  }

  static Future<void> deleteAssets(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // delete assets
    for (int x = 0; x < test.assets.length; x++) {
      await CommonTest.tapByKey(tester, "delete$x",
          seconds: CommonTest.waitTime);
    }

    // check assets
    for (int x = 0; x < test.assets.length; x++) {
      expect('N', CommonTest.getTextField("status$x"));
    }
  }

  static Future<void> updateAssets(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.assets[0].assetName != test.assets[0].assetName) return;
    List<Asset> updAssets = [];
    for (Asset asset in test.assets) {
      updAssets.add(asset.copyWith(
        assetName: '${asset.assetName!}u',
        quantityOnHand: Decimal.parse(asset.quantityOnHand.toString()) +
            Decimal.parse('10'),
      ));
    }
    test = test.copyWith(assets: updAssets);
    await enterAssetData(tester, test.assets);
    await checkAssetDetail(tester, test.assets);
    await PersistFunctions.persistTest(test);
  }
}
