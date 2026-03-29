/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:decimal/decimal.dart';
import 'package:growerp_models/growerp_models.dart';

import '../demo_progress_helper.dart';

// ── Progress ──────────────────────────────────────────────────────────────────

final linerDemoProgress = DemoProgressHelper('liner_demo');

// ── Demo data ─────────────────────────────────────────────────────────────────

const _rollStockId = 'LINER-ROLL-60';
const _systemId = 'LINER-SYS-60';
const _routingName = 'Standard Liner';
const _linerTypeName = '60 mil HDPE';
const _customerName = 'customer company2';
const _supplierName = 'supplier company 1';

final _products = [
  Product(
    pseudoId: _rollStockId,
    productName: '60mil HDPE Roll Stock',
    productTypeId: 'Physical Good',
    price: Decimal.parse('1.50'),
    listPrice: Decimal.parse('1.75'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: _systemId,
    productName: 'Pond Liner System 60mil',
    productTypeId: 'Physical Good',
    price: Decimal.parse('2.00'),
    listPrice: Decimal.parse('2.40'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
];

final _linerTypes = [
  LinerType(
    linerName: _linerTypeName,
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.306'),
  ),
  LinerType(
    linerName: '40 mil LLDPE',
    widthIncrement: Decimal.parse('22.5'),
    rollStockWidth: Decimal.parse('23.0'),
    linerWeight: Decimal.parse('0.204'),
  ),
];

final _panels = [
  (panelName: 'Panel 1', width: '45', length: '100'),
  (panelName: 'Panel 2', width: '22.5', length: '50'),
];

final _customerAddress = Address(
  address1: '123 Demo Street',
  city: 'Tucson',
  province: 'AZ',
  postalCode: '85701',
  country: 'United States',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<Product?> _findProduct(RestClient rc, String pseudoId) async {
  final result = await rc.getProduct(
    searchString: pseudoId,
    isForDropDown: true,
    limit: 5,
  );
  return result.products.where((p) => p.pseudoId == pseudoId).firstOrNull;
}

Future<Product> _ensureProduct(
  RestClient rc,
  String classificationId,
  Product product,
) async {
  final existing = await _findProduct(rc, product.pseudoId);
  if (existing != null) return existing;
  return rc.createProduct(product: product, classificationId: classificationId);
}

Future<Company> _ensureCompany(RestClient rc, Company company) async {
  final result = await rc.getCompany(
    role: company.role,
    searchString: company.name,
    limit: 5,
  );
  final existing =
      result.companies.where((c) => c.name == company.name).firstOrNull;
  if (existing != null) return existing;
  return rc.createCompany(company: company);
}

Future<LinerType?> _findLinerType(RestClient rc, String name) async {
  final result = await rc.getLinerTypes(search: name, limit: 5);
  return result.linerTypes.where((t) => t.linerName == name).firstOrNull;
}

// ── Phase actions ─────────────────────────────────────────────────────────────

/// Phase 0 – Create products, BOM, liner types, and companies.
Future<String> linerSetupData(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  for (final p in _products) {
    await _ensureProduct(rc, classificationId, p);
  }

  final system = await _findProduct(rc, _systemId);
  if (system == null) throw Exception('Liner system product not found after creation.');

  final boms = await rc.getBoms(search: _systemId, limit: 5);
  final bomExists = boms.boms.any((b) => b.productPseudoId == _systemId);
  if (!bomExists) {
    await rc.createBomItem(
      bomItem: BomItem(
        productId: system.productId,
        productPseudoId: system.pseudoId,
        toProductId: _rollStockId,
        componentPseudoId: _rollStockId,
        quantity: Decimal.one,
      ),
    );
  }

  for (final lt in _linerTypes) {
    final existing = await _findLinerType(rc, lt.linerName!);
    if (existing == null) {
      await rc.createLinerType(linerType: lt);
    }
  }

  await _ensureCompany(
    rc,
    Company(
      name: _customerName,
      role: Role.customer,
      address: _customerAddress,
    ),
  );
  await _ensureCompany(
    rc,
    Company(name: _supplierName, role: Role.supplier),
  );

  return 'Created liner products, BOM, liner types (60mil HDPE, 40mil LLDPE), '
      'and demo companies.';
}

/// Phase 1 – Create production routing with four tasks.
Future<String> linerCreateRouting(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final existing = await rc.getRoutings(search: _routingName, limit: 5);
  Routing routing = existing.routings
      .where((r) => r.routingName == _routingName)
      .firstOrNull ?? await rc.createRouting(
    routing: Routing(
      routingName: _routingName,
      description: 'Cut → Seam → QC Inspection → Fold & Package',
    ),
  );

  final tasks = await rc.getRoutingTasks(routingId: routing.routingId);
  if (tasks.routingTasks.isEmpty) {
    for (final (name, seq, hours, center) in [
      ('Cut', 10, '0.5', 'Cutting Station'),
      ('Seam', 20, '1.0', 'Welding Station'),
      ('QC Inspection', 30, '0.25', 'QC Station'),
      ('Fold & Package', 40, '0.5', 'Packaging Station'),
    ]) {
      await rc.createRoutingTask(
        routingTask: RoutingTask(
          routingId: routing.routingId,
          taskName: name,
          sequenceNum: seq,
          estimatedWorkTime: Decimal.parse(hours),
          workCenterName: center,
        ),
      );
    }
  }

  return 'Routing "$_routingName" created: '
      'Cut → Seam → QC Inspection → Fold & Package.';
}

/// Phase 2 – Create a sales order for 1× Pond Liner System.
Future<String> linerCreateSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final system = await _findProduct(rc, _systemId);
  if (system == null) throw Exception('$_systemId not found. Run Setup first.');

  final customers = await rc.getCompany(
    role: Role.customer,
    searchString: _customerName,
    limit: 5,
  );
  final customer =
      customers.companies.where((c) => c.name == _customerName).firstOrNull;
  if (customer == null) throw Exception('Demo customer not found. Run Setup first.');

  final so = await rc.createFinDoc(
    finDoc: FinDoc(
      sales: true,
      docType: FinDocType.order,
      description: 'Pond liner installation — Phase 1',
      otherCompany: customer,
      items: [
        FinDocItem(
          product: system,
          quantity: Decimal.one,
          price: Decimal.parse('2.00'),
        ),
      ],
    ),
  );
  final placed = await rc.updateFinDoc(
    finDoc: so.copyWith(status: FinDocStatusVal.created),
  );
  await linerDemoProgress.saveSalesOrderId(placed.orderId ?? '', ownerPartyId);
  return 'Sales order ${placed.pseudoId} created for 1× Pond Liner System 60mil.';
}

/// Phase 3 – Approve sales order → backend auto-creates a Work Order.
Future<String> linerApproveSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final soId = await linerDemoProgress.getSalesOrderId(ownerPartyId);
  if (soId == null || soId.isEmpty) {
    throw Exception('No sales order saved. Create the sales order first.');
  }
  final result = await rc.getFinDoc(
    finDocId: soId,
    sales: true,
    docType: FinDocType.order,
    limit: 1,
  );
  final so = result.finDocs.firstOrNull;
  if (so == null) throw Exception('Sales order $soId not found.');

  final approved = await rc.updateFinDoc(
    finDoc: so.copyWith(status: FinDocStatusVal.approved),
  );
  return 'Sales order ${approved.pseudoId} approved. Work Order auto-created by backend.';
}

/// Phase 4 – Assign routing and add liner panels to the Work Order.
Future<String> linerAddPanelsToWorkOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final wos = await rc.getWorkOrder(search: _systemId, limit: 5);
  final wo = wos.workOrders
      .where(
        (w) =>
            w.status == null ||
            w.status == WorkOrderStatusVal.inPlanning ||
            w.status == WorkOrderStatusVal.approved,
      )
      .firstOrNull;
  if (wo == null) {
    throw Exception('No active work order found. Approve the sales order first.');
  }

  // Assign routing if not already set
  if (wo.routingId == null || wo.routingId!.isEmpty) {
    final routings = await rc.getRoutings(search: _routingName, limit: 5);
    final routing =
        routings.routings.where((r) => r.routingName == _routingName).firstOrNull;
    if (routing != null) {
      await rc.updateWorkOrder(
        workOrder: wo.copyWith(routingId: routing.routingId),
      );
    }
  }

  // Add liner panels
  final linerType = await _findLinerType(rc, _linerTypeName);
  for (final p in _panels) {
    await rc.createLinerPanel(
      linerPanel: LinerPanel(
        workEffortId: wo.workEffortId,
        linerTypeId: linerType?.linerTypeId ?? _linerTypeName,
        panelName: p.panelName,
        panelWidth: Decimal.parse(p.width),
        panelLength: Decimal.parse(p.length),
      ),
    );
  }

  return 'Routing assigned and ${_panels.length} liner panels added to work order. '
      'System computed SqFt, Passes, and Weight for each panel.';
}

/// Phase 5 – Purchase 5 rolls of roll stock and complete payment.
Future<String> linerPurchaseRollStock(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final suppliers = await rc.getCompany(
    role: Role.supplier,
    searchString: _supplierName,
    limit: 5,
  );
  final supplier =
      suppliers.companies.where((c) => c.name == _supplierName).firstOrNull;
  if (supplier == null) throw Exception('Demo supplier not found. Run Setup first.');

  final rollStock = await _findProduct(rc, _rollStockId);
  if (rollStock == null) throw Exception('$_rollStockId not found. Run Setup first.');

  final po = await rc.createFinDoc(
    finDoc: FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'Roll stock replenishment',
      otherCompany: supplier,
      items: [
        FinDocItem(
          product: rollStock,
          quantity: Decimal.parse('5'),
          price: Decimal.parse('1.50'),
        ),
      ],
    ),
  );
  final placed = await rc.updateFinDoc(
    finDoc: po.copyWith(status: FinDocStatusVal.created),
  );
  final approved = await rc.updateFinDoc(
    finDoc: placed.copyWith(status: FinDocStatusVal.approved),
  );
  await linerDemoProgress.savePurchaseOrderId(approved.orderId ?? '', ownerPartyId);

  final payments = await rc.getFinDoc(
    sales: false,
    docType: FinDocType.payment,
    status: FinDocStatusVal.created,
    limit: 10,
  );
  final payment = payments.finDocs.firstOrNull;
  if (payment != null) {
    final approvedPay = await rc.updateFinDoc(
      finDoc: payment.copyWith(status: FinDocStatusVal.approved),
    );
    await rc.updateFinDoc(
      finDoc: approvedPay.copyWith(status: FinDocStatusVal.completed),
    );
  }

  return 'PO ${approved.pseudoId} created. 5 rolls of 60mil HDPE Roll Stock ordered and payment completed.';
}

/// Phase 6 – Approve and receive the incoming shipment.
Future<String> linerReceiveRollStock(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final shipments = await rc.getFinDoc(
    sales: false,
    docType: FinDocType.shipment,
    status: FinDocStatusVal.created,
    limit: 5,
  );
  final shipment = shipments.finDocs.firstOrNull;
  if (shipment == null) {
    throw Exception('No incoming shipment found. Approve the purchase order first.');
  }

  final approved = await rc.updateFinDoc(
    finDoc: shipment.copyWith(status: FinDocStatusVal.approved),
  );

  final locations = await rc.getLocation(limit: 1);
  final loc = locations.locations.firstOrNull;

  FinDoc toReceive = approved;
  if (loc != null && approved.items.isNotEmpty) {
    final updatedItems = approved.items
        .map((item) => item.copyWith(asset: Asset(location: loc)))
        .toList();
    toReceive = approved.copyWith(items: updatedItems);
  }

  await rc.receiveShipment(finDoc: toReceive);
  return 'Roll stock received into warehouse. Work Order shortage is cleared.';
}

/// Phase 7 – Release, start, and complete the Work Order.
Future<String> linerCompleteProduction(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  WorkOrders wos = await rc.getWorkOrder(search: _systemId, limit: 5);
  WorkOrder? wo = wos.workOrders
      .where(
        (w) =>
            w.status == null ||
            w.status == WorkOrderStatusVal.inPlanning ||
            w.status == WorkOrderStatusVal.approved ||
            w.status == WorkOrderStatusVal.inProgress,
      )
      .firstOrNull;
  if (wo == null) {
    throw Exception('No active work order found. Approve the sales order first.');
  }

  if (wo.status == null || wo.status == WorkOrderStatusVal.inPlanning) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.approved),
    );
  }
  if (wo.status == WorkOrderStatusVal.approved) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.inProgress),
    );
  }
  if (wo.status == WorkOrderStatusVal.inProgress) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.complete),
    );
  }

  return 'Production complete. Roll stock consumed, '
      '1× Pond Liner System 60mil added to finished-goods inventory.';
}

/// Phase 8 – Ship to customer and collect payment.
Future<String> linerShipAndCollect(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final shipments = await rc.getFinDoc(
    sales: true,
    docType: FinDocType.shipment,
    status: FinDocStatusVal.created,
    limit: 5,
  );
  final shipment = shipments.finDocs.firstOrNull;
  if (shipment == null) {
    throw Exception('No outgoing shipment found. Complete the work order first.');
  }

  final approved = await rc.updateFinDoc(
    finDoc: shipment.copyWith(status: FinDocStatusVal.approved),
  );
  await rc.updateFinDoc(
    finDoc: approved.copyWith(status: FinDocStatusVal.completed),
  );

  final payments = await rc.getFinDoc(
    sales: true,
    docType: FinDocType.payment,
    status: FinDocStatusVal.created,
    limit: 10,
  );
  final payment = payments.finDocs.firstOrNull;
  if (payment != null) {
    final approvedPay = await rc.updateFinDoc(
      finDoc: payment.copyWith(status: FinDocStatusVal.approved),
    );
    await rc.updateFinDoc(
      finDoc: approvedPay.copyWith(status: FinDocStatusVal.completed),
    );
  }

  return 'Liner system shipped to customer and payment collected.';
}

/// Phase 9 – Recalculate ledger and statistics.
Future<String> linerUpdateStats(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  await rc.calculateLedger();
  await rc.recalculateStatistics(ownerPartyId: ownerPartyId);
  final txns = await rc.getFinDoc(docType: FinDocType.transaction, limit: 5);
  return 'Ledger and statistics updated. Found ${txns.finDocs.length} GL transactions.';
}
