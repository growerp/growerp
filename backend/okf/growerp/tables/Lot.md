---
type: Moqui Entity
title: Lot
description: "Lot"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.Lot
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Lot

Lot

Full entity name: `mantle.product.asset.Lot`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `lotId` | id | Y |  |
| `mfgPartyId` | id |  |  |
| `lotNumber` | text-short |  |  |
| `quantity` | number-decimal |  |  |
| `manufacturedDate` | date-time |  |  |
| `expirationDate` | date |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Mfg Party](Party.md) via `mfgPartyId`
- many [Asset](Asset.md) via `lotId`
- many [PhysicalInventoryCount](PhysicalInventoryCount.md) via `lotId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.Lot
