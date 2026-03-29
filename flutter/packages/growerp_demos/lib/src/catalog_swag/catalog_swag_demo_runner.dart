/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

import '../generic_demo_runner.dart';
import 'catalog_swag_demo_service.dart';

const _phases = [
  DemoPhase(
    title: 'Setup: Create Demo Products & BOM',
    description:
        'Creates the Moqui Marketing Package (SWAG-PKG-001) and its three '
        'components (Baseball Cap, Coffee Mug, USB Drive) together with a '
        'Bill of Materials and demo customer/supplier companies. '
        'Skipped automatically if the data already exists.',
    widgetName: 'BomList',
    action: setupDemoData,
  ),
  DemoPhase(
    title: 'Create Sales Order',
    description:
        'A customer orders 2× Moqui Marketing Package. '
        'The order is saved in Created state so you can review it '
        'before approving.',
    widgetName: 'SalesOrderList',
    action: createSalesOrder,
  ),
  DemoPhase(
    title: 'Approve Sales Order',
    description:
        'Approving the sales order triggers the backend to automatically '
        'create a Work Order because the product has a Bill of Materials.',
    widgetName: 'SalesOrderList',
    action: approveSalesOrder,
  ),
  DemoPhase(
    title: 'View Work Order — Material Shortage',
    description:
        'The system created a Work Order for the 2 kits. '
        'It shows a material shortage for all three components '
        'because no swag items are in the warehouse yet.',
    widgetName: 'WorkOrderList',
    action: viewWorkOrder,
  ),
  DemoPhase(
    title: 'Order & Pay for Components',
    description:
        'A purchase order is raised for 3 each of Baseball Cap, Coffee Mug, '
        'and USB Drive. The order is approved and payment is processed.',
    widgetName: 'PurchaseOrderList',
    action: createAndApprovePurchaseOrder,
  ),
  DemoPhase(
    title: 'Receive Components into Warehouse',
    description:
        'The incoming shipment from the supplier is received. '
        'Caps, mugs, and USB drives are now in stock and the Work Order '
        'shortage is cleared.',
    widgetName: 'IncomingShipmentList',
    action: receiveIncomingShipment,
  ),
  DemoPhase(
    title: 'Assemble the Kits',
    description:
        'The Work Order is released, started, and completed. '
        'Components are consumed and 2× Moqui Marketing Package '
        'are added to finished-goods inventory.',
    widgetName: 'WorkOrderList',
    action: completeWorkOrder,
  ),
  DemoPhase(
    title: 'Ship to Customer & Collect Payment',
    description:
        'The finished kits are shipped to the customer. '
        'The outgoing shipment is approved, completed, and '
        'customer payment is collected.',
    widgetName: 'OutgoingShipmentList',
    action: shipToCustomerAndCollectPayment,
  ),
  DemoPhase(
    title: 'Update Statistics & Ledger Totals',
    description:
        'Runs the ledger recalculation and statistics update jobs for this '
        'company. Dashboard numbers, balance sheet totals, and GL account '
        'summaries are refreshed to reflect all completed transactions.',
    widgetName: 'TransactionList',
    action: updateStatsAndLedger,
  ),
];

class CatalogSwagDemoRunner extends StatelessWidget {
  const CatalogSwagDemoRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericDemoRunner(
      title: 'Catalog & Manufacturing Demo',
      phases: _phases,
      progress: catalogSwagProgress,
    );
  }
}
