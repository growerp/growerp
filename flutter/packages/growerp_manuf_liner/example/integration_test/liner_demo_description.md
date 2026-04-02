# GrowERP Liner Panel Manufacturing — Demo Walkthrough

This document describes the end-to-end business process shown in the demo movie.
The demo runs inside **GrowERP**, an open-source ERP system, and follows a single
liner job from initial setup all the way through shipping and final accounting.

---

## Setup — New Company and Demo Data

The demo starts by creating a fresh company and loading all the master data needed
for the job:

- Two **products**: the raw material (*60 mil HDPE Roll Stock*) and the finished
  good (*Pond Liner System 60 mil*) that will be sold to the customer.
- A **Bill of Materials** that links the two products (one roll of stock per liner
  system).
- One **warehouse location** where inventory will be stored.
- A **customer** company (who will order the liner) and a **supplier** company
  (who will provide the raw material).

---

## Phase 1 — Liner Types: Material Catalog

The factory works with different grades of plastic sheeting. In this phase two
**liner types** are defined in the system:

| Liner Type    | Width Increment | Weight (lb/sq ft) |
|---------------|-----------------|-------------------|
| 60 mil HDPE   | 22.5 ft         | 0.306             |
| 40 mil LLDPE  | 22.5 ft         | 0.204             |

These properties drive all the automatic calculations later — the system uses
them to compute panel area, the number of passes through the cutting machine,
and the total weight of each panel.

---

## Phase 2 — Production Routing

A **routing** defines the sequence of operations that every liner job goes
through on the shop floor. The *Standard Liner* routing has four steps:

| Step | Operation       | Work Centre        | Est. Time |
|------|-----------------|--------------------|-----------|
| 10   | Cut             | Cutting Station    | 0.5 h     |
| 20   | Seam            | Welding Station    | 1.0 h     |
| 30   | QC Inspection   | QC Station         | 0.25 h    |
| 40   | Fold & Package  | Packaging Station  | 0.5 h     |

The routing is created and all four tasks are entered and verified in the system.

---

## Phase 3 — Bill of Materials

The **Bill of Materials (BOM)** for *Pond Liner System 60 mil* is reviewed. It
shows that producing one finished liner system requires:

> **1 × 60 mil HDPE Roll Stock**

This link between the finished product and its raw material is what allows
GrowERP to automatically check inventory and flag shortages.

---

## Phase 4 — Sales Order

A customer places an order for **1 × Pond Liner System 60 mil**. The order is
entered in GrowERP with the price and customer details, then **approved**.

Because the product has a Bill of Materials, approving the sales order
**automatically creates a Work Order** — no manual step is needed. GrowERP
knows that fulfilling this sale requires a manufacturing run.

---

## Phase 5 — Work Order and Liner Panels

The automatically created **Work Order** is opened. The *Standard Liner* routing
is assigned to it so the shop floor knows which operations to perform.

Two **liner panels** are then entered for this specific job:

| Panel   | Width  | Length  |
|---------|--------|---------|
| Panel 1 | 45 ft  | 100 ft  |
| Panel 2 | 22.5 ft| 50 ft   |

For each panel the system automatically computes:

- **Square footage** — the total area of the panel.
- **Number of passes** — how many strips of roll stock are needed.
- **Weight** — total weight based on the liner type's weight factor.

The computed values are verified on screen to confirm the calculations are
correct.

---

## Phase 6 — Purchasing Roll Stock

Back on the Work Order, GrowERP displays a **material shortage** — there is no
roll stock currently in the warehouse.

To resolve this, a **purchase order** is created for **5 rolls of 60 mil HDPE
Roll Stock** from the supplier. The purchase order is approved and the payment
is processed, completing the procurement cycle.

---

## Phase 7 — Receiving Roll Stock into the Warehouse

The supplier ships the roll stock. In GrowERP the incoming **shipment is
approved and received** into the designated warehouse location.

Once received, the inventory balance updates and the Work Order no longer shows
a shortage — the material is ready for production.

---

## Phase 8 — Running Production

The Work Order moves through its production lifecycle:

1. **Release** — the order is released to the shop floor.
2. **Start** — production begins.
3. **Print Production Order** — the system generates a **PDF shop-floor document**
   with all the panel details, routing steps, and quantities. This document
   travels with the job on the factory floor.
4. **Complete** — production is finished.

When the Work Order is completed, GrowERP automatically:

- **Consumes** the roll stock from inventory.
- **Adds** 1 × Pond Liner System 60 mil to finished-goods inventory.

---

## Phase 9 — Shipping to the Customer

With the finished liner system in inventory, the outgoing **shipment to the
customer** is processed:

1. The shipment is **approved**.
2. The shipment is **completed** — the product leaves the warehouse.
3. The **customer payment** is approved and completed.

---

## Phase 10 — Purchase and Sales Invoices

GrowERP **automatically generates invoices** from the approved orders:

- The **purchase invoice** reflects the cost of the roll stock received from
  the supplier.
- The **sales invoice** captures the revenue from the customer order.

Both invoices are visible in the accounting module and ready for reconciliation.

---

## Phase 11 — Accounting and General Ledger Transactions

Every financial event throughout the job — inventory purchases, cost of goods
sold (COGS), customer revenue, and payments — is **automatically posted to the
general ledger**. The GL transaction list shows the complete audit trail for
this liner job.

---

## Phase 12 — Ledger Summarize & Statistics

Before viewing the report, GrowERP **recalculates all ledger summaries and
company statistics** on the backend. This step ensures that every posted
transaction is fully consolidated and that the dashboard figures — total
assets, liabilities, revenue and costs — are up to date.

The accounting dashboard is then refreshed so the tiles show live numbers
reflecting the completed liner job.

---

## Phase 13 — Revenue and Expense Report

The demo closes with the **Revenue & Expense Report**, which summarises all
financial activity. The report shows:

- **Revenue** from the customer sale.
- **Costs** from the raw material purchase and production.
- The resulting **profit** from this single liner job.

---

## Full Business Lifecycle — Summary

```
Liner Types  →  Routing  →  Bill of Materials  →  Sales Order
      ↓
  Work Order  →  Liner Panels (computed: sqft / passes / weight)
      ↓
  Purchase Order  →  Receive into Warehouse  →  Production Run
      ↓
  Print Shop-Floor PDF  →  Complete Work Order  →  Ship to Customer
      ↓
  Purchase Invoice  →  Sales Invoice  →  GL Transactions
      ↓
  Ledger Summarize & Statistics  →  Revenue & Expense Report
```

The entire cycle — from defining materials to reviewing the profit — is managed
within GrowERP without switching between systems or manually transferring data.
