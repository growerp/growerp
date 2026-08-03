---
type: Moqui Entity
title: AssetIdentification
description: "Asset Identification"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetIdentification
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetIdentification

Asset Identification

Full entity name: `mantle.product.asset.AssetIdentification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `identificationTypeEnumId` | id | Y |  |
| `idValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one `moqui.basic.Enumeration` via `identificationTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetIdentification
