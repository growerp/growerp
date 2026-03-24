/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:decimal/decimal.dart';
import 'package:growerp_models/growerp_models.dart';

import 'demo_progress_service.dart';

// ── Demo data definitions ────────────────────────────────────────────────────

final _swagProducts = [
  Product(
    pseudoId: 'SWAG-CAP-001',
    productName: 'Moqui Baseball Cap',
    productTypeId: 'Physical Good',
    price: Decimal.parse('8.00'),
    listPrice: Decimal.parse('10.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'SWAG-MUG-001',
    productName: 'Moqui Coffee Mug',
    productTypeId: 'Physical Good',
    price: Decimal.parse('7.00'),
    listPrice: Decimal.parse('9.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
  Product(
    pseudoId: 'SWAG-USB-001',
    productName: 'Moqui USB Drive',
    productTypeId: 'Physical Good',
    price: Decimal.parse('5.00'),
    listPrice: Decimal.parse('8.00'),
    useWarehouse: true,
    assetClassId: 'AsClsInventoryFin',
  ),
];

// Assembly product (parent of the BOM)
final _swagPackage = Product(
  pseudoId: 'SWAG-PKG-001',
  productName: 'Moqui Marketing Package',
  productTypeId: 'Physical Good',
  useWarehouse: true,
  assetClassId: 'AsClsInventoryFin',
);

const _customerName = 'customer company2';
const _supplierName = 'supplier company 1';

// Demo customer address — required by the backend when approving a sales order.
final _customerAddress = Address(
  address1: '123 Demo Street',
  city: 'Tucson',
  province: 'AZ',
  postalCode: '85701',
  country: 'United States',
);

// ── Helper functions ─────────────────────────────────────────────────────────

/// Finds a product by pseudoId. Returns null if not found.
Future<Product?> _findProduct(RestClient rc, String pseudoId) async {
  final result = await rc.getProduct(
    searchString: pseudoId,
    isForDropDown: true,
    limit: 5,
  );
  return result.products.where((p) => p.pseudoId == pseudoId).firstOrNull;
}

/// Finds or creates a product by pseudoId.
Future<Product> _ensureProduct(
  RestClient rc,
  String classificationId,
  Product product,
) async {
  final existing = await _findProduct(rc, product.pseudoId);
  if (existing != null) return existing;
  return rc.createProduct(
    product: product,
    classificationId: classificationId,
  );
}

/// Finds or creates a company by name and role.
Future<Company> _ensureCompany(RestClient rc, Company company) async {
  final result = await rc.getCompany(
    role: company.role,
    searchString: company.name,
    limit: 5,
  );
  final existing = result.companies
      .where((c) => c.name == company.name)
      .firstOrNull;
  if (existing != null) return existing;
  return rc.createCompany(company: company);
}

// ── Demo phase actions ───────────────────────────────────────────────────────

/// Phase 0 – Create swag products, the assembly product, and the BOM.
/// Also ensures demo customer and supplier companies exist.
Future<String> setupDemoData(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  // Ensure component products
  for (final p in _swagProducts) {
    await _ensureProduct(rc, classificationId, p);
  }

  // Ensure assembly product
  final pkg = await _ensureProduct(rc, classificationId, _swagPackage);

  // Check if BOM already exists for the assembly product
  final boms = await rc.getBoms(search: _swagPackage.pseudoId, limit: 5);
  final bomExists = boms.boms.any(
    (b) => b.productPseudoId == _swagPackage.pseudoId,
  );

  if (!bomExists) {
    // Create BOM items: 1× each component under the assembly product
    final components = [
      ('SWAG-CAP-001', Decimal.one),
      ('SWAG-MUG-001', Decimal.one),
      ('SWAG-USB-001', Decimal.one),
    ];
    for (final (compId, qty) in components) {
      await rc.createBomItem(
        bomItem: BomItem(
          productId: pkg.productId,
          productPseudoId: pkg.pseudoId,
          // Backend resolves component by pseudoId in toProductId field
          toProductId: compId,
          componentPseudoId: compId,
          quantity: qty,
        ),
      );
    }
  }

  // Ensure demo customer and supplier companies
  await _ensureCompany(
    rc,
    Company(name: _customerName, role: Role.customer, address: _customerAddress),
  );
  await _ensureCompany(
    rc,
    Company(name: _supplierName, role: Role.supplier),
  );

  return 'Created swag products, BOM, and demo companies.';
}

/// Phase 1 – Create a sales order for 2× Moqui Marketing Package in Created state.
/// Saves the order ID so the next phase can approve it.
Future<String> createSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final pkg = await _findProduct(rc, _swagPackage.pseudoId);
  if (pkg == null) throw Exception('SWAG-PKG-001 product not found. Run Setup first.');

  final customers = await rc.getCompany(
    role: Role.customer,
    searchString: _customerName,
    limit: 5,
  );
  final customer = customers.companies
      .where((c) => c.name == _customerName)
      .firstOrNull;
  if (customer == null) throw Exception('Demo customer not found. Run Setup first.');

  final so = await rc.createFinDoc(
    finDoc: FinDoc(
      sales: true,
      docType: FinDocType.order,
      description: 'Moqui swag order',
      otherCompany: customer,
      items: [
        FinDocItem(
          product: pkg,
          quantity: Decimal.parse('2'),
          price: Decimal.parse('35.00'),
        ),
      ],
    ),
  );

  // Move from inPreparation (Open/Tentative) → created (Placed)
  final placed = await rc.updateFinDoc(
    finDoc: so.copyWith(status: FinDocStatusVal.created),
  );

  await DemoProgressService.saveSalesOrderId(placed.orderId ?? '', ownerPartyId);
  return 'Sales order ${placed.pseudoId} created. Ready to review and approve.';
}

/// Phase 2 – Approve the sales order created in Phase 1.
/// Approving auto-creates a Work Order (because a BOM exists).
Future<String> approveSalesOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final soId = await DemoProgressService.getSalesOrderId(ownerPartyId);
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
  return 'Sales order ${approved.pseudoId} approved. '
      'Work order auto-created by backend.';
}

/// Phase 2 – Navigation only: user views the auto-created work order.
/// Returns a description; no API call needed.
Future<String> viewWorkOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final wos = await rc.getWorkOrder(search: _swagPackage.pseudoId, limit: 5);
  final count = wos.workOrders.length;
  return 'Found $count work order(s) for Moqui Marketing Package. '
      'The shortage panel shows 0 inventory for all components.';
}

/// Phase 3 – Create a purchase order for swag components, approve it,
/// then find and complete the resulting purchase payment.
Future<String> createAndApprovePurchaseOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  final suppliers = await rc.getCompany(
    role: Role.supplier,
    searchString: _supplierName,
    limit: 5,
  );
  final supplier = suppliers.companies
      .where((c) => c.name == _supplierName)
      .firstOrNull;
  if (supplier == null) throw Exception('Demo supplier not found. Run Setup first.');

  // Fetch component products to get their productIds
  final cap = await _findProduct(rc, 'SWAG-CAP-001');
  final mug = await _findProduct(rc, 'SWAG-MUG-001');
  final usb = await _findProduct(rc, 'SWAG-USB-001');
  if (cap == null || mug == null || usb == null) {
    throw Exception('Swag component products not found. Run Setup first.');
  }

  final po = await rc.createFinDoc(
    finDoc: FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'Moqui swag components PO',
      otherCompany: supplier,
      items: [
        FinDocItem(
          product: cap,
          quantity: Decimal.parse('3'),
          price: Decimal.parse('8.00'),
        ),
        FinDocItem(
          product: mug,
          quantity: Decimal.parse('3'),
          price: Decimal.parse('7.00'),
        ),
        FinDocItem(
          product: usb,
          quantity: Decimal.parse('3'),
          price: Decimal.parse('5.00'),
        ),
      ],
    ),
  );

  // Move from inPreparation (Open/Tentative) → created (Placed) → approved
  final placed = await rc.updateFinDoc(
    finDoc: po.copyWith(status: FinDocStatusVal.created),
  );
  final approved = await rc.updateFinDoc(
    finDoc: placed.copyWith(status: FinDocStatusVal.approved),
  );
  await DemoProgressService.savePurchaseOrderId(approved.orderId ?? '', ownerPartyId);

  // Find and complete the purchase payment generated by PO approval
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

  return 'Purchase order ${approved.pseudoId} created, approved, and payment completed.';
}

/// Phase 4 – Approve and receive the incoming shipment for swag components.
Future<String> receiveIncomingShipment(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  // Find the incoming shipment in 'created' status
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

  // Approve the shipment
  final approved = await rc.updateFinDoc(
    finDoc: shipment.copyWith(status: FinDocStatusVal.approved),
  );

  // Try to find a warehouse location to receive into
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
  return 'Incoming shipment received. Caps, Mugs, and USB drives are now in stock.';
}

/// Phase 5 – Release, start, and complete the work order for Moqui Marketing Package.
Future<String> completeWorkOrder(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  WorkOrders wos = await rc.getWorkOrder(
    search: _swagPackage.pseudoId,
    limit: 5,
  );
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
    throw Exception('No active work order found for Moqui Marketing Package. '
        'Approve the sales order first.');
  }

  // Release (In Planning → Approved)
  if (wo.status == null || wo.status == WorkOrderStatusVal.inPlanning) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.approved),
    );
  }

  // Start (Approved → In Progress)
  if (wo.status == WorkOrderStatusVal.approved) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.inProgress),
    );
  }

  // Complete (In Progress → Complete)
  if (wo.status == WorkOrderStatusVal.inProgress) {
    wo = await rc.updateWorkOrder(
      workOrder: wo.copyWith(status: WorkOrderStatusVal.complete),
    );
  }

  return 'Work order completed. Components consumed, 2× Moqui Marketing Package '
      'added to finished-goods inventory.';
}

/// Phase 6 – Approve and complete the outgoing shipment, then collect sales payment.
Future<String> shipToCustomerAndCollectPayment(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  // Find outgoing shipment in 'created' status
  final shipments = await rc.getFinDoc(
    sales: true,
    docType: FinDocType.shipment,
    status: FinDocStatusVal.created,
    limit: 5,
  );
  final shipment = shipments.finDocs.firstOrNull;
  if (shipment == null) {
    throw Exception(
      'No outgoing shipment found. Complete the work order first.',
    );
  }

  // Approve the shipment
  final approved = await rc.updateFinDoc(
    finDoc: shipment.copyWith(status: FinDocStatusVal.approved),
  );

  // Complete the shipment
  await rc.updateFinDoc(
    finDoc: approved.copyWith(status: FinDocStatusVal.completed),
  );

  // Find and complete the sales payment
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

  return 'Shipment sent and customer payment collected.';
}

/// Phase 8 – Run statistics and ledger totals update jobs, then show GL count.
/// Triggers recalculate#GlAccountOrgSummaries and get#Statistics for the owner.
Future<String> updateStatsAndLedger(
  RestClient rc,
  String classificationId,
  String ownerPartyId,
) async {
  await rc.calculateLedger();
  await rc.recalculateStatistics(ownerPartyId: ownerPartyId);
  final txns = await rc.getFinDoc(
    docType: FinDocType.transaction,
    limit: 5,
  );
  final count = txns.finDocs.length;
  return 'Ledger totals and statistics updated for owner $ownerPartyId. '
      'Found $count GL transactions. Dashboard numbers are now current.';
}
