---
type: Moqui Entity
title: AssetPartyAssignment
description: "Asset Party Assignment"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPartyAssignment
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetPartyAssignment

Asset Party Assignment

Full entity name: `mantle.product.asset.AssetPartyAssignment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `allocatedDate` | date-time |  |  |
| `statusId` | id |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one [Asset](Asset.md) via `assetId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetPartyAssignment
