---
type: Moqui Entity
title: ProductStoreShipOption
description: "Product Store Ship Option"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreShipOption
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreShipOption

Product Store Ship Option

Full entity name: `mantle.product.store.ProductStoreShipOption`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `carrierPartyId` | id | Y |  |
| `shipmentMethodEnumId` | id | Y |  |
| `sequenceNum` | number-integer |  |  |
| `markupPercent` | number-decimal |  |  |
| `markupAmount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreShipOption
