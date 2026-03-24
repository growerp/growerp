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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class WorkOrderTest {
  static Future<void> selectWorkOrders(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/manufacturing/workOrder',
      'WorkOrderList',
    );
  }

  static Future<void> addWorkOrders(
    WidgetTester tester,
    List<WorkOrder> workOrders,
  ) async {
    await enterWorkOrderData(tester, workOrders);
    await checkWorkOrders(tester, workOrders);
  }

  static Future<void> enterWorkOrderData(
    WidgetTester tester,
    List<WorkOrder> workOrders,
  ) async {
    for (WorkOrder workOrder in workOrders) {
      if (workOrder.workEffortId.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: workOrder.pseudoId,
        );
        await CommonTest.tapByKey(tester, 'item0');
      }
      if (workOrder.workEffortName != null) {
        await CommonTest.enterText(tester, 'name', workOrder.workEffortName!);
      }
      if (workOrder.productPseudoId != null) {
        await CommonTest.enterText(
          tester,
          'productId',
          workOrder.productPseudoId!,
        );
      }
      if (workOrder.estimatedQuantity != null) {
        await CommonTest.enterText(
          tester,
          'quantity',
          workOrder.estimatedQuantity.toString(),
        );
      }
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'item0');
    }
  }

  static Future<void> checkWorkOrders(
    WidgetTester tester,
    List<WorkOrder> workOrders,
  ) async {
    for (int i = 0; i < workOrders.length; i++) {
      await CommonTest.waitForKey(tester, 'pseudoId$i');
      expect(
        CommonTest.getTextField('pseudoId$i').isNotEmpty,
        true,
        reason: 'Work order $i should have a non-empty pseudoId',
      );
    }
  }

  static Future<void> deleteWorkOrder(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'delete$index');
    await CommonTest.tapByKey(tester, 'continue');
  }

  /// Open the work order dialog for the item at [index] in the list.
  static Future<void> openWorkOrder(WidgetTester tester, int index) async {
    await CommonTest.tapByKey(tester, 'item$index');
    await CommonTest.waitForKey(tester, 'WorkOrderDialog');
  }

  /// Verify the status label inside an open work order dialog.
  static Future<void> checkWorkOrderStatus(
    WidgetTester tester,
    String expectedStatus,
  ) async {
    await CommonTest.waitForKey(tester, 'statusLabel');
    expect(
      CommonTest.getTextField('statusLabel'),
      contains(expectedStatus),
      reason: 'Work order status should contain $expectedStatus',
    );
  }

  /// Verify shortage display for each [components] entry.
  /// Each map must have keys: 'pseudoId' (String), 'haveQty' (String).
  static Future<void> checkShortage(
    WidgetTester tester,
    List<Map<String, dynamic>> components,
  ) async {
    for (final comp in components) {
      final key = 'have${comp['pseudoId']}';
      await CommonTest.waitForKey(tester, key);
      expect(
        CommonTest.getTextField(key),
        contains(comp['haveQty'].toString()),
        reason:
            'Component ${comp['pseudoId']} should show have qty ${comp['haveQty']}',
      );
    }
  }

  /// Tap Release button (In Planning → Approved). Waits for list to return.
  static Future<void> releaseWorkOrder(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'releaseButton', seconds: 3);
    await CommonTest.waitForKey(tester, 'WorkOrderList');
  }

  /// Tap Start button (Approved → In Progress). Waits for list to return.
  static Future<void> startWorkOrder(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'startButton', seconds: 3);
    await CommonTest.waitForKey(tester, 'WorkOrderList');
  }

  /// Tap Complete button (In Progress → Complete). Waits for list to return.
  static Future<void> completeWorkOrder(WidgetTester tester) async {
    await CommonTest.tapByKey(tester, 'completeButton', seconds: 3);
    await CommonTest.waitForKey(tester, 'WorkOrderList');
  }
}
