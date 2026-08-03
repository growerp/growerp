---
type: Moqui Entity
title: ProductGlAppl
description: "Used to specify relevant GL Accounts for a Product (expense, revenue, etc); not related to posting conf"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductGlAppl
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductGlAppl

Used to specify relevant GL Accounts for a Product (expense, revenue, etc); not related to posting conf

Full entity name: `mantle.product.ProductGlAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `glAccountId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductGlAppl
