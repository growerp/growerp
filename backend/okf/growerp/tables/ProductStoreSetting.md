---
type: Moqui Entity
title: ProductStoreSetting
description: "Product Store Setting"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreSetting
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreSetting

Product Store Setting

Full entity name: `mantle.product.store.ProductStoreSetting`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `settingTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `settingValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `settingTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreSetting
