# Manufacturing Lifecycle — End-to-End Workflow

**File:** `flutter/packages/admin/integration_test/manufacturing_lifecycle_test.dart`
**Packages:** `growerp_manufacturing`, `growerp_order_accounting`, `growerp_models`

---

## What This Test Validates

This integration test walks through the complete manufacturing lifecycle: from receiving a customer order, through procuring raw materials, running production, and finally delivering the finished goods and collecting payment. All financial transactions are verified in the accounting ledger at the end.

It is the primary automated check that the manufacturing module works correctly end-to-end in GrowERP.

---

## Sample Scenario

| Role | Item |
|------|------|
| Finished good | Widget Assembly (MFG-ASSY-001) — sells for $50 |
| Component A | Bolt M5 (MFG-COMP-A) — 2 bolts required per assembly |
| Component B | Bearing 6201 (MFG-COMP-B) — 1 bearing required per assembly |
| Customer | Standard test customer |
| Supplier | Standard test supplier |

**Bill of Materials (BOM):** 1× Widget Assembly = 2× Bolt M5 + 1× Bearing 6201

---

## Workflow Steps

### Step 1 — Initial Setup
The system is initialised with the three products above, the bill of materials, a warehouse location, and the trading partners (customer and supplier). This mirrors what an administrator would configure before production begins.

### Step 2 — BOM Verification
The bill of materials is opened and checked to confirm that both components (Bolt M5 and Bearing 6201) are listed correctly. This ensures the recipe used for production is accurate before any orders are placed.

### Step 3 — Sales Order
A sales order is created for **1 unit of Widget Assembly** from the customer. When the order is approved, GrowERP automatically generates a **Work Order** for the required quantity. No manual intervention is needed to trigger this.

### Step 4 — Shortage Check
The newly created work order is opened. At this point no components are in stock, so the work order displays a **material shortage**:

| Component | Required | Available |
|-----------|----------|-----------|
| Bolt M5 | 2 | 0 |
| Bearing 6201 | 1 | 0 |

This shortage view helps planners decide what to purchase.

### Step 5 — Purchase Order
A purchase order is raised with the supplier for **5× Bolt M5 ($1.00 each)** and **3× Bearing 6201 ($5.00 each)** — more than the minimum required, which is realistic for bulk buying. The order is approved and the supplier payment is processed.

### Step 6 — Receive Components into Warehouse
The inbound shipment from the supplier is approved and received into the warehouse. The components are now available in inventory, eliminating the shortages flagged in Step 4.

### Step 7 — Production Run
With components in stock, the work order moves through three stages:

| Stage | Status |
|-------|--------|
| Released for production | `In Planning` → `Approved` |
| Production started | `Approved` → `In Progress` |
| Production completed | `In Progress` → `Completed` |

When completed, the 2 Bolt M5 and 1 Bearing 6201 are **consumed from inventory** and **1 Widget Assembly is added** as finished goods stock.

### Step 8 — Shipment to Customer & Payment
The finished Widget Assembly is shipped to the customer via an outbound shipment. The shipment is approved and completed. The customer payment is then collected and confirmed.

### Step 9 — Accounting Verification
The ledger is checked to confirm that all key events generated accounting entries:
- Purchase order approval
- Component receipt
- Work order completion (material consumption + production output)
- Customer shipment
- Payments (both supplier and customer)

---

## How to Run the Test

From the `flutter/` directory, with a GrowERP backend running on port 8080:

```bash
cd packages/admin
flutter test integration_test/manufacturing_lifecycle_test.dart \
  --dart-define=BACKEND_PORT=8080
```

The test clears all existing data before running (`clear: true`), so it is safe to run against a development backend.

---

## Dependencies

| Package | Role |
|---------|------|
| `growerp_manufacturing` | BOM and Work Order BLoC, views, and test helpers |
| `growerp_order_accounting` | Sales/purchase orders, shipments, payments, ledger |
| `growerp_models` | Shared data models (`Product`, `BomItem`, `FinDoc`, etc.) |
| `growerp_core` | Common test utilities (`CommonTest`, `PersistFunctions`) |

---

## Related Moqui Backend Services

The backend logic exercised by this test lives in:

- `moqui/runtime/component/growerp/service/growerp/100/ManufacturingServices100.xml` — work order creation and status transitions
- `moqui/runtime/component/growerp/service/growerp/100/FinDocServices100.xml` — orders, shipments, payments
- `moqui/runtime/component/growerp/entity/GrowerpViewEntities.xml` — BOM and work order views
