# growerp_manuf_liner

A GrowERP building-block package that extends [`growerp_manufacturing`](../growerp_manufacturing/README.md)
with **liner-panel manufacturing** capabilities: a material catalogue (Liner Types), a per-panel
QC tracking system (Liner Panels), and a shop-floor **production-order PDF** generator.

It is designed for factories that cut and seam flexible geomembrane or geotextile materials
(pond liners, landfill liners, etc.) where each panel has a distinct width, length, and liner type,
and the shop floor needs a printed production order showing the panel list, liner totals, and BOM.

## Features

### Liner Types — material catalogue

- Define every plastic material used in the factory: name, width increment, roll-stock width, and weight per square foot.
- The weight field drives automatic panel-weight calculations.
- Full CRUD — searchable list, dialog form, delete with confirmation.

### Liner Panels — per-panel QC tracking

- Attach an ordered list of panels to any Work Order.
- Each panel captures: panel name, liner type (dropdown), width (ft), and length (ft).
- **Computed fields** (read-only in the dialog, calculated server-side):
  - `panelSqft` — width × length
  - `passes` — how many roll-stock passes are needed given `widthIncrement`
  - `weight` — sqft × `linerWeight` from the chosen Liner Type
- A **QC number** (`qcNum`) is auto-assigned by the backend on creation.
- Panels are embedded inside the Work Order dialog via `extraTabBuilder`, keeping the
  production context visible at all times.
- Panels can also be filtered by `salesOrderId` to show only panels for a specific customer order.

### Production-order PDF

```dart
await printProductionOrder(workOrder);
```

Generates and previews a formatted PDF containing:

| Section | Content |
|---|---|
| Header | WO #, product, quantity, start date, routing, notes |
| Panels table | QC#, panel name, liner, width, length, sqft, passes, weight |
| Liner totals | Total sqft and estimated weight, grouped by liner type |
| BOM items | Product ID and quantity for each component |

Uses the [`pdf`](https://pub.dev/packages/pdf) and [`printing`](https://pub.dev/packages/printing) packages.

## Architecture

The package follows the GrowERP BLoC pattern:

```
growerp_manuf_liner/lib/src/
├── liner_type/
│   ├── blocs/        # LinerTypeBloc, LinerTypeEvent, LinerTypeState
│   ├── views/        # LinerTypeList, LinerTypeDialog
│   └── integration_test/  # LinerTypeTest
├── liner_panel/
│   ├── blocs/        # LinerPanelBloc, LinerPanelEvent, LinerPanelState
│   ├── views/        # LinerPanelList, LinerPanelDialog
│   └── integration_test/  # LinerPanelTest
└── production_order/
    └── production_order_pdf.dart   # printProductionOrder()
```

All backend communication goes through `growerp_models` REST client endpoints:

| Entity | Endpoint |
|---|---|
| Liner Types | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/LinerType(s)` |
| Liner Panels | `GET/POST/PATCH/DELETE /rest/s1/growerp/100/LinerPanel(s)` |

## Adding to an App

1. Add the dependency to your `pubspec.yaml`:

   ```yaml
   dependencies:
     growerp_manuf_liner: ^1.0.0
   ```

2. Register BLoC providers using the helper:

   ```dart
   import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';

   blocProviders: [
     ...getManufacturingBlocProviders(restClient),  // from growerp_manufacturing
     ...getLinerBlocProviders(restClient),
     // ... other providers
   ],
   ```

3. Wire up routes in your router:

   ```dart
   '/liner/linerType'         => const LinerTypeList(),
   '/manufacturing/workOrder' => WorkOrderList(
     extraTabBuilder: (workOrder) => [
       SizedBox(
         height: 300,
         child: LinerPanelList(workEffortId: workOrder.workEffortId),
       ),
     ],
     extraActionBuilder: (workOrder) => [
       IconButton(
         key: const Key('printProductionOrder'),
         icon: const Icon(Icons.print),
         onPressed: () => printProductionOrder(workOrder),
       ),
     ],
   ),
   ```

4. Add menu items (example):

   ```dart
   MenuItem(title: 'Liner Types',  route: '/liner/linerType',        iconName: 'layers'),
   MenuItem(title: 'Work Orders',  route: '/manufacturing/workOrder', iconName: 'precision_manufacturing'),
   ```

## Integration Tests

All integration tests live in `example/integration_test/`. Run from the `example/` sub-package
(requires a running Moqui backend on port 8080 and a connected device/emulator):

```bash
cd flutter/packages/growerp_manuf_liner/example
flutter test integration_test/<test-file>.dart \
    -d <device-id> \
    --dart-define=BACKEND_PORT=8080
```

### Focused unit tests

These tests cover the **extra functions** specific to this package, independent of the full
order-accounting lifecycle. Each test creates a fresh company and tears it down on logout.

#### `liner_type_test.dart` — LinerType CRUD

Exercises the material catalogue managed by `LinerTypeBloc`.

| Step | Action |
|---|---|
| Setup | Fresh company + admin created. |
| 1 | Navigate to the Liner Types list (`/liner/linerType`). |
| 2 | Add two liner types: **60 mil HDPE** (0.306 lb/sqft, 22.5 ft increment) and **40 mil LLDPE** (0.204 lb/sqft). |
| 3 | Verify both names appear in the list (backend returns newest-first). |
| 4 | Open the first item — confirm the `LinerTypeDialog` opens with pre-filled fields. |
| 5 | Delete the first liner type and confirm removal. |
| Teardown | Logout. |

#### `liner_panel_test.dart` — LinerPanel with computed fields

Exercises `LinerPanelBloc` and the auto-calculation of sqft, passes, and weight.
Panels are accessed through the Work Order dialog's embedded tab.

| Step | Action |
|---|---|
| Setup | Fresh company + admin, with one product pre-loaded (`LINER-SYS-60`). |
| 1 | Add one liner type (**60 mil HDPE**) so the panel dialog dropdown is populated. |
| 2 | Navigate to Work Orders and create a work order for `LINER-SYS-60`. |
| 3 | Open the work order — the Liner Panels tab is shown via `extraTabBuilder`. |
| 4 | Add **Panel A** (45 ft × 100 ft) and **Panel B** (22.5 ft × 50 ft). |
| 5 | Verify both panels have a server-assigned `qcNum` (non-empty). |
| 6 | Open Panel A — confirm `panelSqft`, `passes`, and `weight` fields are present. |
| 7 | Delete Panel B. |
| Teardown | Close the Work Order dialog and logout. |

### End-to-end demo

#### Demo: Pond Liner System (`liner_demo_test.dart`)

Full lifecycle — from material setup through production PDF and accounting — using a
**Pond Liner System 60mil** finished good and **60 mil HDPE Roll Stock** raw material.

| Phase | What happens |
|---|---|
| Setup | Products, BOM, warehouse location, and trading partners loaded into a fresh company. |
| 1 — Liner Types | Two liner materials defined: 60 mil HDPE and 40 mil LLDPE. |
| 2 — Routing | **Standard Liner** routing created with four tasks: Cut → Seam → QC Inspection → Fold & Package. |
| 3 — BOM | BOM for Pond Liner System 60mil viewed (1 × Roll Stock pre-loaded). |
| 4 — Sales Order | Customer orders 1 × Pond Liner System. Order approved — **Work Order auto-created**. |
| 5 — Liner Panels | Work Order opened; routing assigned; two liner panels added (Panel 1: 45×100 ft, Panel 2: 22.5×50 ft). Computed fields verified. |
| 6 — Purchase | Purchase order for 5 rolls of roll stock raised, approved, and paid. |
| 7 — Receive | Incoming shipment approved and received into the warehouse; material shortage cleared. |
| 8 — Production | Work Order released → started → **Print button** tapped (generates PDF) → completed. Finished good enters stock. |
| 9 — Ship | Outgoing shipment to customer approved and completed; sales payment collected. |
| 10 — Accounting | General ledger reviewed — inventory cost, COGS, revenue, and all payments posted. |

## Backend

The Moqui services that power this package live in:

```
moqui/runtime/component/growerp/service/growerp/100/ManufacturingServices100.xml
```

Key services: `get#LinerTypes`, `create#LinerType`, `update#LinerType`, `delete#LinerType`,
`get#LinerPanels`, `create#LinerPanel` (auto-assigns QC number, computes sqft/passes/weight),
`update#LinerPanel`, `delete#LinerPanel`.


## End-User Workflow

In GrowERP, the Liner Manufacturing module is designed specifically for businesses that fabricate large, custom-sized products out of rolled flat materials—for example, swimming pool liners, truck tarpaulins, or industrial geomembranes.

Instead of just tracking generic parts in a Bill of Materials, this module helps you calculate exactly how to cut and assemble the final product from flat sheets.

Here is an end-user explanation of how the workflow operates:

### 1. Define Your Materials (Liner Types)
First, you set up your Liner Types. This represents the master rolls of raw material you keep in inventory (e.g., "20 mil Blue Vinyl", "Heavy Duty Canvas", or "Clear PVC").

### 2. Enter Custom Dimensions (Liner Panels)
When you receive an order for a custom liner, you create a Production Order (Work Order). Because material usually comes in fixed-width rolls (like 6 feet wide), a large 20x40 pool liner can't be cut in one piece. It has to be built by welding multiple "panels" together.

You add individual Liner Panels to the order. For each piece you need your shop floor to cut, you specify:
* **Liner Type:** Which raw material roll to use.
* **Dimensions:** The specific Width and Length in feet.
* **Panel Name (Optional):** A friendly name so the shop knows what the piece is for (e.g., "Deep End Wall", "Shallow Floor").

### 3. Automatic Shop Floor Calculations
As you enter these panels, the system does the heavy lifting for you. It automatically calculates:
* **Square Footage (SqFt):** The area of each panel to track material consumption.
* **Estimated Weight:** The weight of each panel and the total weight of the finished product. This is critical for knowing if a liner will be too heavy for a standard pallet or if it requires special shipping logistics.
* **Welding/Sewing Passes:** It estimates the number of "passes" the shop floor will need to make to seam all these panels together into the final product.

### 4. Tracking and Quality Control (QC#)
Every single panel you enter is automatically assigned a unique QC# (Quality Control Number). This allows your production team to label every piece as it is cut, ensuring nothing gets lost and everything is welded in the correct order.

### 5. Generate the Production Document
Finally, you can generate a Printable Production Order (PDF). This acts as the "Traveler" document that you hand to your manufacturing team. It includes:
* Header details (Work Order #, Routing details, Start Date).
* A summary of the total square footage and total weight needed per material type.
* A detailed, row-by-row table showing every single panel to be cut, including its QC#, dimensions, and material type, so the floor workers know exactly what to produce.