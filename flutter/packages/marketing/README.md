# GrowERP Marketing App

GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter) focused on marketing:
campaigns, leads, social outreach, website/CMS and light sales/order tracking.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees
- `growerp_sales` — CRM opportunities/pipeline
- `growerp_order_accounting` — orders, invoices, payments, ledger
- `growerp_marketing` — campaigns, leads
- `growerp_outreach` — social media outreach/posting
- `growerp_website` — CMS pages, chat widget
- `growerp_wiki` — wiki/knowledge pages
- `growerp_activity` — tasks/activities
- `growerp_adk` — AI chat assistant, agent/job/approval/action management

App-specific: `MarketingDbForm` (marketing dashboard config).

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`marketing`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
