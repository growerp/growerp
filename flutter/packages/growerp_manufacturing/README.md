# growerp_manufacturing

A GrowERP building-block package that adds **Bill of Materials (BOM)** and **Work Order** management to any GrowERP application. It integrates with inventory, purchasing, sales, and the general ledger through the Moqui backend.

## Features

### Bill of Materials (BOM)

- Define assemblies by linking a finished-good product to its component parts.
- Specify quantity, scrap factor, and build sequence per component.
- Real-time availability check: the BOM dialog flags component shortages against current warehouse stock.
- BOMs are created and maintained interactively through the UI or pre-loaded via test-data helpers.

### Work Orders

- A **Work Order** (production run) is created for a finished-good product with a target quantity and optional start/completion dates.
- **Automatic creation**: approving a sales order for a product with a BOM automatically generates the corresponding work order.
- **Four-stage lifecycle** managed by simple action buttons:

  | Button | Status transition |
  |---|---|
  | Release to Shop Floor | `WeInPlanning` → `WeApproved` |
  | Start Production | `WeApproved` → `WeInProgress` |
  | Complete Production | `WeInProgress` → `WeComplete` |

- The work order dialog shows every BOM component with its required quantity and current stock, highlighted in red when stock is insufficient.
- On **completion**, components are automatically consumed from inventory and the finished good is received into stock.
- **Component cost summary** (shown at completion): each BOM line displays its unit purchase cost and total line cost; the dialog footer shows the total production cost across all components.

## Architecture

The package follows the GrowERP BLoC pattern:

```
growerp_manufacturing/lib/src/
├── bom/
│   ├── blocs/        # BomBloc, BomEvent, BomState
│   ├── views/        # BomList, BomDialog
│   └── integration_test/  # BomTest
└── work_order/
    ├── blocs/        # WorkOrderBloc, WorkOrderEvent, WorkOrderState
    ├── views/        # WorkOrderList, WorkOrderDialog
    └── integration_test/  # WorkOrderTest
```

All backend communication goes through `growerp_models` REST client endpoints:

| Entity | Endpoint |
|---|---|
| BOM items | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/BomItem(s)` |
| Work Orders | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/WorkOrder(s)` |

## Adding to an App

1. Add the dependency to your `pubspec.yaml`:

   ```yaml
   dependencies:
     growerp_manufacturing: ^1.0.0
   ```

2. Register BLoC providers using the helper:

   ```dart
   import 'package:growerp_manufacturing/growerp_manufacturing.dart';

   blocProviders: [
     ...getManufacturingBlocProviders(restClient),
     // ... other providers
   ],
   ```

3. Wire up routes in your router:

   ```dart
   '/manufacturing/bom'       => const BomList(),
   '/manufacturing/workOrder' => const WorkOrderList(),
   ```

4. Add menu items (example):

   ```dart
   MenuItem(title: 'BOM',         route: '/manufacturing/bom',       iconName: 'schema'),
   MenuItem(title: 'Work Orders', route: '/manufacturing/workOrder',  iconName: 'precision_manufacturing'),
   ```

## Demo: Catalog & Swag Manufacturing

The `admin` app contains a self-contained end-to-end demo in
[`integration_test/catalog_swag_demo_test.dart`](../admin/integration_test/catalog_swag_demo_test.dart)
that walks through the full manufacturing lifecycle using a "Moqui Swag Kit" scenario:

| Phase | What happens |
|---|---|
| 1 | A fresh company is created with catalog demo data and three swag component products (Baseball Cap, Coffee Mug, USB Drive). |
| 2 | The **Moqui Marketing Package** BOM is built interactively through the BOM UI, bundling one of each component into a kit. |
| 3 | A sales order for 2 × Moqui Marketing Package is created and approved, which **automatically generates a Work Order**. |
| 4 | The Work Order is opened — it shows a material shortage for all three components. |
| 5 | A purchase order for the swag components is raised, approved, and paid. |
| 6 | The incoming shipment is received into the warehouse; the Work Order shortage clears. |
| 7 | The Work Order is released → started → completed. Components are consumed and 2 finished kits enter inventory. The dialog shows the component costs and total production cost. |
| 8 | The finished kits are shipped to the customer and payment is collected. |
| 9 | The general ledger is reviewed — inventory cost, COGS, revenue, and payments are all posted automatically. |

**Run the demo** (requires a running Moqui backend on port 8080 and a connected device/emulator):

```bash
cd flutter/packages/admin
flutter test integration_test/catalog_swag_demo_test.dart \
    -d <device-id> \
    --dart-define=BACKEND_PORT=8080
```

A simpler standalone manufacturing demo (without catalog data) is available in
[`integration_test/manufacturing_demo_test.dart`](../admin/integration_test/manufacturing_demo_test.dart).
It uses a **Widget Assembly** finished good with two components (Bolt M5 and Bearing 6201)
and follows the same eight-phase lifecycle.

```bash
flutter test integration_test/manufacturing_demo_test.dart \
    -d <device-id> \
    --dart-define=BACKEND_PORT=8080
```

## Backend

The Moqui services that power this package live in:

```
moqui/runtime/component/growerp/service/growerp/100/ManufacturingServices100.xml
```

Key services: `get#WorkOrder`, `create#WorkOrder`, `update#WorkOrder` (handles status
transitions and inventory issuance/receipt on completion), `get#BomItems`, `create#BomItem`,
`update#BomItem`, `delete#BomItem`.
