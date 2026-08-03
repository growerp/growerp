---
type: Moqui Entity
title: ProductStoreApproveParam
description: "Product Store Approve Param"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreApproveParam
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreApproveParam

Product Store Approve Param

Full entity name: `mantle.product.store.ProductStoreApproveParam`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storeApproveId` | id | Y |  |
| `parameterName` | text-short | Y |  |
| `parameterValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStoreApprove](ProductStoreApprove.md) via `storeApproveId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreApproveParam
