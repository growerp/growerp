---
type: Moqui Entity
title: AssetIssuanceParty
description: "Asset Issuance Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetIssuanceParty
tags: [mantle, product, issuance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetIssuanceParty

Asset Issuance Party

Full entity name: `mantle.product.issuance.AssetIssuanceParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetIssuanceId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssetIssuance](AssetIssuance.md) via `assetIssuanceId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetIssuanceParty
