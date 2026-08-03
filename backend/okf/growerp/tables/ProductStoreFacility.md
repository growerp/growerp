---
type: Moqui Entity
title: ProductStoreFacility
description: "Product Store Facility"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreFacility
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreFacility

Product Store Facility

Full entity name: `mantle.product.store.ProductStoreFacility`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `facilityId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Facility](Facility.md) via `facilityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreFacility
