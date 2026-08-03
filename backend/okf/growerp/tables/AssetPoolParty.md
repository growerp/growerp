---
type: Moqui Entity
title: AssetPoolParty
description: "Asset Pool Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPoolParty
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetPoolParty

Asset Pool Party

Full entity name: `mantle.product.asset.AssetPoolParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetPoolId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssetPool](AssetPool.md) via `assetPoolId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPoolParty
