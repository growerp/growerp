---
type: Moqui Entity
title: ProductStoreGroup
description: "Product Store Group"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroup
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreGroup

Product Store Group

Full entity name: `mantle.product.store.ProductStoreGroup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreGroupId` | id | Y |  |
| `storeGroupTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `storeGroupTypeEnumId`
- many [ProductStoreGroupMember](ProductStoreGroupMember.md) via `productStoreGroupId`
- many [ProductStoreGroupParty](ProductStoreGroupParty.md) via `productStoreGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreGroup
