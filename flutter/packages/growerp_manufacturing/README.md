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
├── routing/
│   ├── blocs/        # RoutingBloc, RoutingEvent, RoutingState
│   ├── views/        # RoutingList, RoutingDialog
│   └── integration_test/  # RoutingTest
└── work_order/
    ├── blocs/        # WorkOrderBloc, WorkOrderEvent, WorkOrderState
    ├── views/        # WorkOrderList, WorkOrderDialog
    └── integration_test/  # WorkOrderTest
```

All backend communication goes through `growerp_models` REST client endpoints:

| Entity | Endpoint |
|---|---|
| BOM items | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/BomItem(s)` |
| Production Routings | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/Routing(s)` |
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

## Integration Tests

All integration tests live in `example/integration_test/`. Run from the `example/` sub-package
(requires a running Moqui backend on port 8080 and a connected device/emulator):

```bash
cd flutter/packages/growerp_manufacturing/example
flutter test integration_test/<test-file>.dart \
    -d <device-id> \
    --dart-define=BACKEND_PORT=8080
```

### Unit tests

| File | What it covers |
|---|---|
| `bom_test.dart` | Create, list, delete a BOM with components |
| `work_order_test.dart` | Create and delete a work order |
| `routing_test.dart` | Create a routing with three tasks, then delete |
| `manufacturing_test.dart` | Aggregator — runs all three unit tests in sequence |

### End-to-end demos

#### Demo: Widget Assembly (`manufacturing_demo_test.dart`)

Uses a **Widget Assembly** finished good with two components (Bolt M5, Bearing 6201).

| Phase | What happens |
|---|---|
| Setup | Products, BOM, warehouse locations, and trading partners are created. |
| 1 | BOM is viewed in the UI. |
| 2 | A production routing with three tasks (Prepare Components, Assemble, Quality Check) is created and linked to the BOM. |
| 3 | A sales order for 1 × Widget Assembly is created and approved — a Work Order is **automatically generated**. |
| 4 | The Work Order shows material shortage; the production routing is assigned. |
| 5 | A purchase order for components is raised, approved, and paid. |
| 6 | Incoming shipment is received into the warehouse; shortages clear. |
| 7 | Work Order is released → started → completed. Components consumed, finished good received into stock with cost summary. |
| 8 | Finished goods shipped to customer; payment collected. |
| 9 | General ledger reviewed — inventory cost, COGS, revenue, and payments all posted. |
| 10 | Dashboard reviewed to confirm updated KPIs. |

#### Demo: Swag Kit (`manufacturing_swag_demo_test.dart`)

Uses swag products (Baseball Cap, Coffee Mug, USB Drive) assembled into a **Moqui Marketing Package** kit.

| Phase | What happens |
|---|---|
| Setup | Fresh company with swag component products (no pre-loaded catalog data). |
| 1 | **Moqui Marketing Package** BOM built interactively through the BOM UI (1 × each component). |
| 2 | A kit-assembly routing with three operations is created. |
| 3 | Sales order for 2 × Moqui Marketing Package created and approved — Work Order auto-generated. |
| 4 | Work Order shows material shortage; routing assigned. |
| 5 | Purchase order for 3 × each component raised, approved, and paid. |
| 6 | Shipment received; shortages clear. |
| 7 | Work Order released → started → completed; 2 finished kits enter stock with cost summary. |
| 8 | Kits shipped to customer; payment collected. |
| 9 | General ledger reviewed. |
| 10 | Dashboard reviewed to confirm updated KPIs. |

#### Lifecycle test (`manufacturing_lifecycle_test.dart`)

Covers the same Widget Assembly lifecycle as the demo above but **without narration pauses** — intended for automated CI runs rather than live demonstrations.

## Backend

The Moqui services that power this package live in:

```
moqui/runtime/component/growerp/service/growerp/100/ManufacturingServices100.xml
```

Key services: `get#WorkOrder`, `create#WorkOrder`, `update#WorkOrder` (handles status
transitions and inventory issuance/receipt on completion), `get#BomItems`, `create#BomItem`,
`update#BomItem`, `delete#BomItem`, `get#Routing`, `create#Routing`, `update#Routing`,
`delete#Routing`.
