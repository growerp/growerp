# GrowERP Hotel App

GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter) covering hotel
operations: room catalog/rates, reservations, housekeeping and accounting.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees
- `growerp_catalog` — room/product catalog
- `growerp_inventory` — room/asset inventory
- `growerp_order_accounting` — reservations (orders), invoices, payments, ledger
- `growerp_website` — public website/booking pages
- `growerp_rental` — Gantt-style availability/rate scheduling shared with the Rental app
- `growerp_activity` — tasks/activities
- `growerp_adk` — AI chat assistant

App-specific: `HousekeepingForm` (room status/cleaning) and `AccountingForm`.

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`hotel`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
