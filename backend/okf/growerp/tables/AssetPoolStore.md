---
type: Moqui Entity
title: AssetPoolStore
description: "Asset Pool Store"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPoolStore
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetPoolStore

Asset Pool Store

Full entity name: `mantle.product.asset.AssetPoolStore`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetPoolId` | id | Y |  |
| `productStoreId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssetPool](AssetPool.md) via `assetPoolId`
- one [ProductStore](ProductStore.md) via `productStoreId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPoolStore
