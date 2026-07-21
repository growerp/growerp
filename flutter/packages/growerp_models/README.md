# All models used in the GrowERP flutter frontend

The base package all other `growerp_*` building blocks depend on. Provides:

- Data models (`@freezed` + `json_serializable`) for every entity used across GrowERP
  (party/company/user, catalog, inventory, orders/invoices/accounting, activities,
  marketing/outreach, ADK agents, website/wiki, manufacturing, rental, etc.)
- `RestClient` — the retrofit-generated REST client for the Moqui backend
- JSON converters and CSV export helpers shared by every building block

Please see https://www.growerp.com for documentation.
