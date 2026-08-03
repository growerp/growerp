---
type: Moqui Entity
title: AssetPool
description: "Asset Pool"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPool
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetPool

Asset Pool

Full entity name: `mantle.product.asset.AssetPool`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetPoolId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `ownerPartyId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [Asset](Asset.md) via `assetPoolId`
- many [AssetPoolParty](AssetPoolParty.md) via `assetPoolId`
- many [AssetPoolStore](AssetPoolStore.md) via `assetPoolId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPool
