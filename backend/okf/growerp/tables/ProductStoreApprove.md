---
type: Moqui Entity
title: ProductStoreApprove
description: "For per-store configurable pre-approve order validations"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreApprove
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreApprove

For per-store configurable pre-approve order validations

Full entity name: `mantle.product.store.ProductStoreApprove`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storeApproveId` | id | Y |  |
| `productStoreId` | id |  |  |
| `serviceRegisterId` | id |  | Registered Service of type OrderValidate that implements the mantle.order.OrderInfoServices.validate#Order interface |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.service.ServiceRegister` via `serviceRegisterId`
- many [ProductStoreApproveParam](ProductStoreApproveParam.md) via `storeApproveId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreApprove
