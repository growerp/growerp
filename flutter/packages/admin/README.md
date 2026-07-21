# GrowERP Admin App

Flagship GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter). Full-featured
ERP admin covering sales, purchasing, inventory, manufacturing, accounting, marketing,
outreach, website/CMS, wiki, e-learning courses and an embedded ADK AI assistant.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees, roles
- `growerp_catalog` — products, categories, assets
- `growerp_inventory` — inventory, warehouses, shipments
- `growerp_sales` — CRM opportunities/pipeline
- `growerp_order_accounting` — orders, invoices, payments, shipments, ledger, GL accounts
- `growerp_manufacturing` / `growerp_manuf_liner` — production runs, bill of materials
- `growerp_marketing` / `growerp_outreach` — campaigns, leads, social outreach
- `growerp_website` / `growerp_wiki` — CMS pages, chat widget, wiki
- `growerp_courses` — e-learning
- `growerp_activity` — tasks/activities
- `growerp_adk` — AI chat assistant, agent/job/approval/action management
- `growerp_demos` — demo data generation (non-release builds only)

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`admin`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
