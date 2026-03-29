/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

import '../generic_demo_runner.dart';
import 'mfg_demo_service.dart';

const _phases = [
  DemoPhase(
    title: 'Setup: Create Products, BOM & Companies',
    description:
        'Creates Widget Assembly (MFG-ASSY-001) and its components '
        '(Bolt M5, Bearing 6201) with a Bill of Materials: '
        '2×Bolt + 1×Bearing per assembly. Also creates demo customer '
        'and supplier companies.',
    widgetName: 'BomList',
    action: mfgSetupData,
  ),
  DemoPhase(
    title: 'Create Production Routing',
    description:
        'Defines the shop-floor process for Widget Assembly: '
        'three operations in sequence — '
        'Prepare Components (0.5h) → Assemble (1.0h) → Quality Check (0.25h).',
    widgetName: 'RoutingList',
    action: mfgCreateRouting,
  ),
  DemoPhase(
    title: 'Create Sales Order',
    description:
        'A customer orders 1× Widget Assembly. '
        'The order is placed in Created state for review before approving.',
    widgetName: 'SalesOrderList',
    action: mfgCreateSalesOrder,
  ),
  DemoPhase(
    title: 'Approve Sales Order → Auto Work Order',
    description:
        'Approving the sales order triggers the backend to automatically '
        'create a Work Order because the product has a Bill of Materials.',
    widgetName: 'SalesOrderList',
    action: mfgApproveSalesOrder,
  ),
  DemoPhase(
    title: 'Assign Routing to Work Order',
    description:
        'The Work Order shows a material shortage for Bolt M5 and Bearing 6201. '
        'We assign the "Widget Assembly Process" routing so shop-floor steps '
        'are visible in the work order.',
    widgetName: 'WorkOrderList',
    action: mfgAssignRouting,
  ),
  DemoPhase(
    title: 'Purchase Components',
    description:
        'A purchase order is raised for 5×Bolt M5 and 3×Bearing 6201 '
        'to fulfil the Work Order requirements. '
        'The order is approved and payment processed.',
    widgetName: 'PurchaseOrderList',
    action: mfgPurchaseComponents,
  ),
  DemoPhase(
    title: 'Receive Components into Warehouse',
    description:
        'The incoming shipment from the supplier is approved and received. '
        'Components are now in stock and the Work Order shortage is resolved.',
    widgetName: 'IncomingShipmentList',
    action: mfgReceiveComponents,
  ),
  DemoPhase(
    title: 'Run Production',
    description:
        'The Work Order is released, started, and completed. '
        'Components are consumed and 1× Widget Assembly is added to inventory.',
    widgetName: 'WorkOrderList',
    action: mfgCompleteProduction,
  ),
  DemoPhase(
    title: 'Ship to Customer & Collect Payment',
    description:
        'The finished Widget Assembly is shipped to the customer. '
        'Outgoing shipment approved, completed, and payment collected.',
    widgetName: 'OutgoingShipmentList',
    action: mfgShipAndCollect,
  ),
  DemoPhase(
    title: 'Update Statistics & Ledger Totals',
    description:
        'Recalculates GL account summaries and statistics for this company. '
        'All financial movements — inventory cost, COGS, revenue, and '
        'payments — are reflected in the general ledger.',
    widgetName: 'TransactionList',
    action: mfgUpdateStats,
  ),
];

class MfgDemoRunner extends StatelessWidget {
  const MfgDemoRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericDemoRunner(
      title: 'Manufacturing Demo',
      phases: _phases,
      progress: mfgDemoProgress,
    );
  }
}
