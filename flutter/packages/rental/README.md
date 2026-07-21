# GrowERP Rental App

GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter) for equipment-hire
businesses: catalog, availability/rate scheduling, orders/invoicing and inventory.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees
- `growerp_catalog` — rental item catalog
- `growerp_inventory` — asset/inventory tracking
- `growerp_sales` — CRM opportunities/pipeline
- `growerp_order_accounting` — orders, invoices, payments, ledger
- `growerp_marketing` — leads/campaigns
- `growerp_website` — public website
- `growerp_rental` — Gantt-style rate/availability scheduling (shared with the Hotel app)
- `growerp_activity` — tasks/activities
- `growerp_adk` — AI chat assistant

App-specific: `RentalDbForm` (rental dashboard config).

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`rental`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
