---
type: Moqui Entity
title: ItemTypeGlAccount
description: "Item Type Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ItemTypeGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ItemTypeGlAccount

Item Type Gl Account

Full entity name: `mantle.ledger.config.ItemTypeGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `itemTypeEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `direction` | text-indicator | Y | If I for Incoming (Purchase) Invoices and if O for Outgoing (Sales) Invoices. If E is for either. |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ItemTypeGlAccount
