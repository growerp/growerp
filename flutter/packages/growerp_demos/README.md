# GrowERP Demos

Demo runners and demo list screen for the GrowERP system. Registered demos step through a
full, live end-to-end business scenario against a real backend (create products, orders,
work orders, shipments, payments, then review the resulting GL postings) — used for
sales/training walkthroughs inside the Admin app.

Registered demos (`registered_demos.dart`):

- **Catalog & Manufacturing Demo** — SWAG kit: BOM assembly, sales order, auto-generated
  work order, purchasing, shipping, GL review
- **Manufacturing Demo** — Widget Assembly lifecycle with BOM and production routing
- **Liner Panel Manufacturing Demo** — custom-cut liner panels, QC tracking, production
  order PDF

`DemoListScreen` (`DemoList` widget) is registered only in non-release builds
(`if (!kReleaseMode)`), so demos never ship to production.
