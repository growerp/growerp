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

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

class InventoryTest {
  static Future<void> selectIncomingShipments(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      'dbInventory',
      'FinDocListShipmentsIn',
      '2',
    );
  }

  static Future<void> selectOutgoingShipments(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      'dbInventory',
      'FinDocListShipmentsOut',
      '1',
    );
  }

  static Future<void> selectWareHouseLocations(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      'dbInventory',
      'LocationListLocations',
      '3',
    );
  }

  static Future<void> checkIncomingShipments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    List<FinDoc> finDocs = [];
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // save shipment id with order
      finDocs.add(order.copyWith(shipmentId: CommonTest.getTextField('id0')));
      // check list
      await CommonTest.tapByKey(tester, 'id0'); // open items
      expect(
        CommonTest.getTextField('itemLine0'),
        contains(order.items[0].product?.productId),
        reason: "checking productId",
      );
      await CommonTest.tapByKey(tester, 'id0'); // close items
    }
    await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
  }

  static Future<void> acceptShipmentInInventory(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    expect(
      orders.isNotEmpty,
      true,
      reason: 'This test needs orders created in previous steps',
    );
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      await CommonTest.tapByKey(
        tester,
        'nextStatus0',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.checkWidgetKey(tester, 'ShipmentReceiveDialogPurchase');
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
      await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
    }
  }

  static Future<void> sendOutGoingShipments(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    List<FinDoc> finDocs = [];
    expect(
      orders.isNotEmpty,
      true,
      reason: 'This test needs orders created in previous steps',
    );
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.orderId!);
      // save shipment id with order
      finDocs.add(order.copyWith(shipmentId: CommonTest.getTextField('id0')));
      await CommonTest.tapByKey(
        tester,
        'nextStatus0',
        seconds: CommonTest.waitTime,
      );
      await CommonTest.tapByKey(
        tester,
        'nextStatus0',
        seconds: CommonTest.waitTime,
      );
      expect(CommonTest.getTextField('status0'), equals('Completed'));
    }
    await PersistFunctions.persistTest(test.copyWith(orders: finDocs));
  }

  static Future<void> checkInventoryQOH(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (FinDoc order in orders) {
      await CommonTest.doSearch(tester, searchString: order.shipmentId!);
      expect(
        order.items[0].quantity.toString(),
        CommonTest.getTextField('qoh0'),
      );
    }
  }

  static Future<void> checkInventory(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<FinDoc> orders = test.orders;
    for (final order in orders) {
      for (final item in order.items) {
        // find asset for order product
        final asset = assets.firstWhere(
          // from test data
          (el) => el.product?.productName == item.description,
          orElse: () => Asset(),
        );
        expect(
          asset.location,
          isNotNull,
          reason:
              'Could not find product: ${item.description} in test data asset list',
        );
        // find location (purchase order saved in receive shipments,
        // sales in asset list)
        await CommonTest.doNewSearch(
          tester,
          searchString: order.sales == false
              ? item.asset!.location!.locationName!
              : asset.location!.locationName!,
        );
        late Decimal newQoh;
        if (order.sales == false) {
          newQoh = asset.quantityOnHand! + item.quantity!;
        } else {
          newQoh = asset.quantityOnHand! - item.quantity!;
        }
        expect(Decimal.parse(CommonTest.getTextFormField('qoh')), newQoh);
        await CommonTest.tapByKey(tester, 'cancel');
      }
    }
  }
}
