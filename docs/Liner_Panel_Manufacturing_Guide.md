# Liner Panel Manufacturing — User Guide

This guide walks you through the complete workflow for manufacturing custom geomembrane liner panels using GrowERP, from receiving a customer order to shipping the finished panels.

> **Design reference**: The architecture and implementation plan for this module is documented in
> `/home/hans/.claude/plans/fizzy-knitting-frog.md` (internal plan file) and the backend interface in
> `docs/Flutter_Moqui_REST_Backend_Interface.md`.

---

## Overview

A liner panel is a custom-sized rectangular sheet of plastic geomembrane seamed from roll stock. Each panel is tracked individually with a unique QC number. The system automatically computes:

| Computed field | Formula |
|---|---|
| **Square Feet** | Width × Length |
| **Passes** | (Width ÷ Width Increment) − 1 |
| **Weight (lb)** | SqFt × Liner Weight |

---

## Step 1 — Set Up Liner Types

Before taking orders you need to define the plastic materials you stock. Navigate to **Liner Types** and add at least one material.

| Field | Description |
|---|---|
| **Liner Name** | e.g. "60 mil HDPE" |
| **Width Increment (ft)** | The seaming step size (e.g. 22.5 ft) |
| **Roll Stock Width (ft)** | Physical roll width including seam allowance (e.g. 23 ft) |
| **Weight (lb/sqft)** | Material weight density (e.g. 0.306 lb/sqft for 60 mil HDPE) |

These values drive all automatic panel calculations.

---

## Step 2 — Set Up Products

You need two types of products:

1. **Roll Stock product** — the raw material purchased from your supplier
   - e.g. "60 mil HDPE Roll" — mark it as a physical good with warehouse tracking

2. **Liner System product** — the finished good sold to the customer
   - e.g. "Liner System 60 mil" — physical good, warehouse-tracked

Link them with a **Bill of Materials (BOM)**:
Go to **Manufacturing → BOM**, open the Liner System product, and add the Roll Stock product as a component with an appropriate quantity (e.g. 1 roll per liner system as a planning unit — actual material is tracked via liner panels).

---

## Step 3 — Set Up Production Routing (optional)

A routing defines the sequence of operations on the shop floor. Navigate to **Manufacturing → Routing** and create a routing such as:

| Seq | Operation | Work Center |
|---|---|---|
| 1 | Cut | Cutting Table |
| 2 | Seam | Seaming Machine |
| 3 | QC Inspection | QC Station |
| 4 | Fold & Package | Packaging |

When creating or editing a Work Order you can assign this routing to guide production staff.

---

## Step 4 — Create a Sales Order

Navigate to **Sales Orders** and create a new order for a customer. Add a line item for the Liner System product with the quantity ordered (e.g. 1 liner system for a pond lining project).

**Approve the order.** On approval, GrowERP automatically creates a **Work Order** for the liner system because the product has a BOM.

---

## Step 5 — Review the Work Order

Navigate to **Manufacturing → Work Orders**. You will see the new work order. Open it to review:

- Product, quantity, and target completion date
- BOM components — the system shows whether roll stock is in inventory
- Routing (if assigned)
- **Liner Panels tab** — this is where individual panels for this job are entered

If roll stock inventory is insufficient, the work order will show a **material shortage**. Proceed to Step 6 to purchase stock.

---

## Step 6 — Purchase Roll Stock (if needed)

Navigate to **Purchase Orders** and create an order to your roll stock supplier:

1. Add a line item for the Roll Stock product with the quantity needed
2. Approve the order
3. Record payment (**Accounting → Purchase Payments**)

Then navigate to **Incoming Shipments**, approve the incoming shipment from your supplier, and receive the goods into your warehouse location. The work order shortage indicator will clear once stock is received.

---

## Step 7 — Enter Liner Panels

Open the work order and switch to the **Liner Panels** tab. For each panel to be manufactured:

1. Tap the **+** (Add Panel) button
2. Select the **Liner Type** (e.g. "60 mil HDPE")
3. Enter an optional **Panel Name** (e.g. "Panel A" or a location reference)
4. Enter **Width (ft)** and **Length (ft)**
5. Tap **Add**

The system assigns a sequential **QC Number** and stores the panel. After saving, open any panel to view the computed **SqFt**, **Passes**, and **Weight**.

Repeat for all panels in the job. Typical projects have anywhere from 5 to 200+ panels.

---

## Step 8 — Complete Production

Once all panels are manufactured and QC-inspected:

1. **Release** the work order (status: WeInPlanning → WeApproved)
2. **Start** the work order (status: WeApproved → WeInProgress)
3. **Complete** the work order (status: WeInProgress → WeComplete)

On completion the system:
- Issues the roll stock components from inventory
- Records the production cost
- Adds the finished liner system to inventory

---

## Step 9 — Print the Production Order PDF

From the work order, tap the **Print** (🖨) button to generate a production order PDF. The PDF contains:

- **Header**: Sales Order #, Customer, Project, Date, Target Ship Date, Notes
- **Panels table**: QC# | Panel Name | Liner | Width | Length | SqFt | Passes | Weight
- **Liner Totals**: grouped by liner type — Total SqFt, Estimated Weight
- **BOM Items**: component quantities consumed

This document is used as a shop-floor traveller and quality record.

---

## Step 10 — Ship to Customer

Navigate to **Outgoing Shipments**. The system creates a shipment linked to the approved sales order.

1. Approve the outgoing shipment
2. Complete the shipment (marks goods as shipped, decrements inventory)
3. Record customer payment (**Accounting → Sales Payments**)

---

## Step 11 — Verify Accounting

Navigate to **Accounting → Ledger**. You will see automatic GL entries for:

- Inventory issuance (roll stock consumed)
- Work-in-process cost transfer
- Finished goods received
- COGS posted on shipment
- Revenue and payment

---

## Module Architecture (Developer Reference)

This feature is implemented across two packages:

| Package | Contents |
|---|---|
| `growerp_manufacturing` | Generic BOM, Work Orders, and Production Routing modules |
| `growerp_manuf_liner` | Liner-specific: LinerType catalog, LinerPanel management, Production Order PDF |

The two packages are decoupled via `WorkOrderDialog`'s `extraTabBuilder` / `extraActionBuilder` callbacks — the manufacturing package knows nothing about liner panels; the liner package injects its UI at runtime.

### Key source files

| File | Purpose |
|---|---|
| `growerp_models/lib/src/models/liner_type_model.dart` | `LinerType` data model |
| `growerp_models/lib/src/models/liner_panel_model.dart` | `LinerPanel` data model |
| `growerp_manuf_liner/lib/src/liner_type/` | LinerType BLoC + views |
| `growerp_manuf_liner/lib/src/liner_panel/` | LinerPanel BLoC + views |
| `growerp_manuf_liner/lib/src/production_order/production_order_pdf.dart` | PDF generation |
| `growerp_manufacturing/lib/src/routing/` | Routing BLoC + views |
| `moqui/.../LinerServices100.xml` | Backend CRUD services |
| `moqui/.../GrowerpEntities.xml` | `LinerType`, `LinerPanel` entities |

### Running the demo

```bash
cd flutter/packages/admin
flutter test integration_test/liner_demo_test.dart \
  -d emulator-5554 \
  --dart-define=BACKEND_PORT=8080
```
