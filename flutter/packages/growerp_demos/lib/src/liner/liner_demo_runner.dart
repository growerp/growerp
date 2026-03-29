/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

import '../generic_demo_runner.dart';
import 'liner_demo_service.dart';

const _phases = [
  DemoPhase(
    title: 'Setup: Products, BOM, Liner Types & Companies',
    description:
        'Creates Pond Liner System 60mil (LINER-SYS-60) and 60mil HDPE Roll '
        'Stock (LINER-ROLL-60) with a BOM: 1 roll per liner system. '
        'Also creates two liner types (60mil HDPE, 40mil LLDPE) and '
        'demo customer/supplier companies.',
    widgetName: 'LinerTypeList',
    action: linerSetupData,
  ),
  DemoPhase(
    title: 'Create Production Routing',
    description:
        'Defines the liner production process: '
        'Cut (0.5h) → Seam (1.0h) → QC Inspection (0.25h) → '
        'Fold & Package (0.5h), each assigned to a work centre.',
    widgetName: 'RoutingList',
    action: linerCreateRouting,
  ),
  DemoPhase(
    title: 'Create Sales Order',
    description:
        'A customer orders 1× Pond Liner System 60mil. '
        'The order is placed in Created state for review before approving.',
    widgetName: 'SalesOrderList',
    action: linerCreateSalesOrder,
  ),
  DemoPhase(
    title: 'Approve Sales Order → Auto Work Order',
    description:
        'Approving the sales order triggers the backend to automatically '
        'create a Work Order because the product has a Bill of Materials.',
    widgetName: 'SalesOrderList',
    action: linerApproveSalesOrder,
  ),
  DemoPhase(
    title: 'Add Liner Panels to Work Order',
    description:
        'The routing is assigned to the Work Order, then two liner panels '
        'are entered: Panel 1 (45ft × 100ft) and Panel 2 (22.5ft × 50ft). '
        'The system automatically computes SqFt, Passes, and Weight for each.',
    widgetName: 'WorkOrderList',
    action: linerAddPanelsToWorkOrder,
  ),
  DemoPhase(
    title: 'Purchase Roll Stock',
    description:
        'The Work Order shows a material shortage — no roll stock in inventory. '
        'A purchase order for 5 rolls of 60mil HDPE Roll Stock is created, '
        'approved, and payment processed.',
    widgetName: 'PurchaseOrderList',
    action: linerPurchaseRollStock,
  ),
  DemoPhase(
    title: 'Receive Roll Stock into Warehouse',
    description:
        'The incoming shipment from the supplier is approved and received. '
        'Roll stock is now in inventory and the Work Order shortage is resolved.',
    widgetName: 'IncomingShipmentList',
    action: linerReceiveRollStock,
  ),
  DemoPhase(
    title: 'Run Production',
    description:
        'The Work Order is released, started, and completed. '
        'Roll stock is consumed and 1× Pond Liner System is added to inventory.',
    widgetName: 'WorkOrderList',
    action: linerCompleteProduction,
  ),
  DemoPhase(
    title: 'Ship to Customer & Collect Payment',
    description:
        'The finished liner system is shipped to the customer. '
        'Outgoing shipment approved, completed, and sales payment collected.',
    widgetName: 'OutgoingShipmentList',
    action: linerShipAndCollect,
  ),
  DemoPhase(
    title: 'Update Statistics & Ledger Totals',
    description:
        'Recalculates GL account summaries and statistics. '
        'All financial movements — inventory cost, COGS, revenue, and '
        'payments — are now reflected in the general ledger.',
    widgetName: 'TransactionList',
    action: linerUpdateStats,
  ),
];

class LinerDemoRunner extends StatelessWidget {
  const LinerDemoRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericDemoRunner(
      title: 'Liner Panel Manufacturing Demo',
      phases: _phases,
      progress: linerDemoProgress,
    );
  }
}
