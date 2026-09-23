# GrowERP Support App

GrowERP vertical for Android, iOS, Web, Linux and Windows (Flutter) for system
administration and support: registered-app/tenant oversight, user/company
administration, and live system usage/REST statistics.

Built from these building blocks (`flutter/packages/growerp_*`):

- `growerp_user_company` — companies, users, employees, roles
- `growerp_activity` — tasks/activities

App-specific:
- `ApplicationList` — registered applications/tenants overview
- `AdkSystemUsageView` — ADK/system usage monitoring
- `AdkAgentCatalogView` — "Agent Catalog": two tabs, **Promotion** (review/promote a
  tenant-nominated agent into the shared `_NA_` catalog) and **Suggestion** (the tenant-facing
  "Suggest a function" AI feasibility check, run here on behalf of a named tenant, since
  support's own session has no tenant of its own)
- `WebsiteToolsView` — "Website Tools": two tabs combining the former separate Website
  Generator (`WebsiteConversionList`) and Website Translation (`WebsiteTranslationList`) screens
- `RestStatisticsView` — REST API call statistics
- `AboutForm`

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`support`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
