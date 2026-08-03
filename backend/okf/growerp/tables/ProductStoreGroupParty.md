---
type: Moqui Entity
title: ProductStoreGroupParty
description: "Product Store Group Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroupParty
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreGroupParty

Product Store Group Party

Full entity name: `mantle.product.store.ProductStoreGroupParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreGroupId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStoreGroup](ProductStoreGroup.md) via `productStoreGroupId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroupParty
