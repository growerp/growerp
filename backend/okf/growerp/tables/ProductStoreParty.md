---
type: Moqui Entity
title: ProductStoreParty
description: "Product Store Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreParty
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreParty

Product Store Party

Full entity name: `mantle.product.store.ProductStoreParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreParty
