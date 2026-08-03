---
type: Moqui Entity
title: ProductCategoryGlAccount
description: "Product Category Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ProductCategoryGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryGlAccount

Product Category Gl Account

Full entity name: `mantle.ledger.config.ProductCategoryGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountTypeEnumId` | id | Y |  |
| `glAccountId` | id |  | Revenue account for products in the category |
| `contraGlAccountId` | id |  | Contra Revenue account for products in the category |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one `moqui.basic.Enumeration` via `glAccountTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.ProductCategoryGlAccount
