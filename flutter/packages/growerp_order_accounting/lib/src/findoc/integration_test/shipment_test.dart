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
