---
type: Moqui Entity
title: AssetGlAppl
description: "Used to specify relevant GL Accounts for an Asset (expense, revenue, etc); not related to posting conf"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetGlAppl
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetGlAppl

Used to specify relevant GL Accounts for an Asset (expense, revenue, etc); not related to posting conf

Full entity name: `mantle.product.asset.AssetGlAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `glAccountId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetGlAppl
