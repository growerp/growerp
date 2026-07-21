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
- `RestStatisticsView` — REST API call statistics
- `AboutForm`

The dashboard, menu and navigation are server-driven (`MenuConfigBloc`, applicationId
`support`) and can be reordered/customized per user.

Backend: Moqui ERP (moqui.org) — see `docs/Flutter_Moqui_REST_Backend_Interface.md` in the
repo root for the REST API, and the root `CLAUDE.md` / `README.md` for setup.
