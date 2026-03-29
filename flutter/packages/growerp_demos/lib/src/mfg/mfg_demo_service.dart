/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:decimal/decimal.dart';
import 'package:growerp_models/growerp_models.dart';

import '../demo_progress_helper.dart';

// ── Progress ──────────────────────────────────────────────────────────────────

final mfgDemoProgress = DemoProgressHelper('mfg_demo');

// ── Demo data ─────────────────────────────────────────────────────────────────

const _assyId = 'MFG-ASSY-001';
const _boltId = 'MFG-COMP-A';
const _bearingId = 'MFG-COMP-B';
const _customerName = 'customer company2';
const _supplierName = 'supplier company 1';
const _routingName = 'Widget Assembly Process';

final _products = [
  Product(
    pseudoId: _assyId,
    productName: 'Widget Assembly',
    productTypeId: 'Physical Good',
    price: Decimal.parse('50.00'),
    listPrice: Decimal.parse('60.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: _boltId,
    productName: 'Bolt M5',
    productTypeId: 'Physical Good',
    price: Decimal.parse('1.00'),
    listPrice: Decimal.parse('1.20'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: _bearingId,
    productName: 'Bearing 6201',
    productTypeId: 'Physical Good',
    price: Decimal.parse('5.00'),
    listPrice: Decimal.parse('6.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
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

// ── Phase actions ─────────────────────────────────────────────────────────────

/// Phase 0 – Create products, BOM, and trading-partner companies.
Future<String> mfgSetupData(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  for (final p in _products) {
    await _ensureProduct(rc, classificationId, p);
  }

  final assy = await _findProduct(rc, _assyId);
  if (assy == null) throw Exception('Assembly product not found after creation.');

  final boms = await rc.getBoms(search: _assyId, limit: 5);
  final bomExists = boms.boms.any((b) => b.productPseudoId == _assyId);

  if (!bomExists) {
    await rc.createBomItem(
      bomItem: BomItem(
        productId: assy.productId,
        productPseudoId: assy.pseudoId,
        toProductId: _boltId,
        componentPseudoId: _boltId,
        quantity: Decimal.parse('2'),
      ),
    );
    await rc.createBomItem(
      bomItem: BomItem(
        productId: assy.productId,
        productPseudoId: assy.pseudoId,
        toProductId: _bearingId,
        componentPseudoId: _bearingId,
        quantity: Decimal.one,
      ),
    );
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

  return 'Created Widget Assembly products, BOM (2×Bolt + 1×Bearing), and demo companies.';
}

/// Phase 1 – Create production routing with three tasks.
Future<String> mfgCreateRouting(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final existing = await rc.getRoutings(search: _routingName, limit: 5);
  Routing routing = existing.routings
      .where((r) => r.routingName == _routingName)
      .firstOrNull ?? await rc.createRouting(
    routing: Routing(routingName: _routingName),
  );

  final tasks = await rc.getRoutingTasks(routingId: routing.routingId);
  if (tasks.routingTasks.isEmpty) {
    for (final (name, seq, hours) in [
      ('Prepare Components', 10, '0.5'),
      ('Assemble', 20, '1.0'),
      ('Quality Check', 30, '0.25'),
    ]) {
      await rc.createRoutingTask(
        routingTask: RoutingTask(
          routingId: routing.routingId,
          taskName: name,
          sequenceNum: seq,
          estimatedWorkTime: Decimal.parse(hours),
        ),
      );
    }
  }

  return 'Routing "$_routingName" created with 3 tasks: '
      'Prepare Components → Assemble → Quality Check.';
}

/// Phase 2 – Create a sales order for 1× Widget Assembly.
Future<String> mfgCreateSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final assy = await _findProduct(rc, _assyId);
  if (assy == null) throw Exception('$_assyId not found. Run Setup first.');

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
      description: 'Manufacturing demo sales order',
      otherCompany: customer,
      items: [
        FinDocItem(
          product: assy,
          quantity: Decimal.one,
          price: Decimal.parse('50.00'),
        ),
      ],
    ),
  );
  final placed = await rc.updateFinDoc(
    finDoc: so.copyWith(status: FinDocStatusVal.created),
  );
  await mfgDemoProgress.saveSalesOrderId(placed.orderId ?? '', ownerPartyId);
  return 'Sales order ${placed.pseudoId} created for 1× Widget Assembly.';
}

/// Phase 3 – Approve the sales order → backend auto-creates a Work Order.
Future<String> mfgApproveSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final soId = await mfgDemoProgress.getSalesOrderId(ownerPartyId);
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

/// Phase 4 – Assign the production routing to the auto-created Work Order.
Future<String> mfgAssignRouting(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final wos = await rc.getWorkOrder(search: _assyId, limit: 5);
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

  final routings = await rc.getRoutings(search: _routingName, limit: 5);
  final routing =
      routings.routings.where((r) => r.routingName == _routingName).firstOrNull;
  if (routing == null) {
    throw Exception('Routing "$_routingName" not found. Create it first.');
  }

  await rc.updateWorkOrder(
    workOrder: wo.copyWith(routingId: routing.routingId),
  );
  return 'Routing "$_routingName" assigned to work order. '
      'Shop-floor steps (Prepare → Assemble → QC) are now visible.';
}

/// Phase 5 – Purchase components (5×Bolt, 3×Bearing) and complete payment.
Future<String> mfgPurchaseComponents(
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

  final bolt = await _findProduct(rc, _boltId);
  final bearing = await _findProduct(rc, _bearingId);
  if (bolt == null || bearing == null) {
    throw Exception('Component products not found. Run Setup first.');
  }

  final po = await rc.createFinDoc(
    finDoc: FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'Widget Assembly components PO',
      otherCompany: supplier,
      items: [
        FinDocItem(
          product: bolt,
          quantity: Decimal.parse('5'),
          price: Decimal.parse('1.00'),
        ),
        FinDocItem(
          product: bearing,
          quantity: Decimal.parse('3'),
          price: Decimal.parse('5.00'),
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
  await mfgDemoProgress.savePurchaseOrderId(approved.orderId ?? '', ownerPartyId);

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

  return 'PO ${approved.pseudoId} created and approved. '
      '5×Bolt M5 and 3×Bearing 6201 ordered. Payment completed.';
}

/// Phase 6 – Approve and receive the incoming shipment.
Future<String> mfgReceiveComponents(
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
  return 'Components received. Bolt M5 and Bearing 6201 are now in stock. '
      'Work Order shortage is cleared.';
}

/// Phase 7 – Release, start, and complete the Work Order.
Future<String> mfgCompleteProduction(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  WorkOrders wos = await rc.getWorkOrder(search: _assyId, limit: 5);
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

  return 'Production complete. Components consumed, '
      '1× Widget Assembly added to finished-goods inventory.';
}

/// Phase 8 – Ship to customer and collect payment.
Future<String> mfgShipAndCollect(
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

  return 'Widget Assembly shipped to customer and payment collected.';
}

/// Phase 9 – Recalculate ledger and statistics.
Future<String> mfgUpdateStats(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  await rc.calculateLedger();
  await rc.recalculateStatistics(ownerPartyId: ownerPartyId);
  final txns = await rc.getFinDoc(docType: FinDocType.transaction, limit: 5);
  return 'Ledger and statistics updated. Found ${txns.finDocs.length} GL transactions.';
}
