---
type: Moqui Entity
title: ProductGlAccount
description: "Product Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ProductGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductGlAccount

Product Gl Account

Full entity name: `mantle.ledger.config.ProductGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountTypeEnumId` | id | Y |  |
| `glAccountId` | id |  | Product Revenue account |
| `contraGlAccountId` | id |  | Product Contra Revenue account |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one `moqui.basic.Enumeration` via `glAccountTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ProductGlAccount
