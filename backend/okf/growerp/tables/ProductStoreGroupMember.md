---
type: Moqui Entity
title: ProductStoreGroupMember
description: "Product Store Group Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroupMember
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreGroupMember

Product Store Group Member

Full entity name: `mantle.product.store.ProductStoreGroupMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreGroupId` | id | Y |  |
| `productStoreId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [ProductStoreGroup](ProductStoreGroup.md) via `productStoreGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroupMember
