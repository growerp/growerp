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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class ShipmentTest {
  static Future<void> selectIncomingShipments(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.selectOption(tester, '/incoming-shipments', 'ShipmentsIn');
  }

  static Future<void> selectOutgoingShipments(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    // Outgoing shipments with key 'ShipmentsOut'
    await CommonTest.selectOption(tester, '/shipments', 'ShipmentsOut');
  }

  static Future<void> receiveShipments(
    WidgetTester tester,
    List<Location> locations,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> newOrders = [];
    for (final (index, order) in test.orders.indexed) {
      debugPrint(
        'DEBUG receiveShipments: searching for shipmentId=${order.shipmentId}',
      );
      await CommonTest.doNewSearch(tester, searchString: order.shipmentId!);
      await CommonTest.checkWidgetKey(tester, 'ShipmentReceiveDialogPurchase');
      debugPrint('DEBUG receiveShipments: ShipmentReceiveDialogPurchase found');
      List<FinDocItem> newItems = [];
      for (final item in order.items) {
        debugPrint(
          'DEBUG receiveShipments: processing item ${item.description}, qty=${item.quantity}',
        );
        // find location where other products already located
        // if not found, use latest location in the list in test data
        final asset = assets.firstWhere(
          // from test data
          (el) => el.product?.productName == item.description,
          orElse: () => Asset(
            location: Location(locationName: locations.last.locationName),
          ),
        );
        debugPrint(
          'DEBUG receiveShipments: entering location=${asset.location!.locationName!} for locationDropDown$index',
        );
        await CommonTest.enterAutocompleteValue(
          tester,
          'locationDropDown$index',
          asset.location!.locationName!,
        );
        // save location to check later
        newItems.add(
          item.copyWith(
            asset: Asset(
              location: Location(locationName: asset.location!.locationName!),
            ),
          ),
        );
      }
      newOrders.add(order.copyWith(items: newItems));
    }
    await PersistFunctions.persistTest(test.copyWith(orders: newOrders));
    debugPrint(
      'DEBUG receiveShipments: tapping first update (confirm locations)',
    );
    await CommonTest.tapByKey(tester, 'update');
    debugPrint(
      'DEBUG receiveShipments: tapping second update (confirm receive)',
    );
    await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    debugPrint('DEBUG receiveShipments: done');
  }
}
