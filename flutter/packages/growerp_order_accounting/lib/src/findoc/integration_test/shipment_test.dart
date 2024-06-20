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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class ShipmentTest {
  static Future<void> selectIncomingShipments(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
        tester, 'dbShipments', 'FinDocListShipmentsIn', '2');
  }

  static Future<void> selectOutgoingShipments(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(
        tester, 'dbShipments', 'FinDocListShipmentsOut', '1');
  }

  static Future<void> receiveShipments(
      WidgetTester tester, List<Location> locations) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> newOrders = [];
    for (final (index, order) in test.orders.indexed) {
      await CommonTest.doNewSearch(tester, searchString: order.shipmentId!);
      await CommonTest.checkWidgetKey(tester, 'ShipmentReceiveDialogPurchase');
      List<FinDocItem> newItems = [];
      for (final item in order.items) {
        // find location where other products already located
        final asset = assets.firstWhere(// from test data
            (el) => el.product?.productName == item.description);
        await CommonTest.enterDropDownSearch(
            tester, 'locationDropDown$index', asset.location!.locationName!);
        // save location to check later
        newItems.add(item.copyWith(
            asset: Asset(
                location:
                    Location(locationName: asset.location!.locationName!))));
      }
      newOrders.add(order.copyWith(items: newItems));
    }
    await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
    await CommonTest.tapByKey(tester, 'update');
    await CommonTest.tapByKey(tester, 'update', seconds: 5);
  }
}
