---
type: Moqui Entity
title: AssetRental
description: "Asset Rental"
resource: http://127.0.0.1:8080/rest/e1/growerp.product.AssetRental
tags: [growerp, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetRental

Asset Rental

Full entity name: `growerp.product.AssetRental`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetRentalId` | id | Y |  |
| `assetId` | id |  |  |
| `productId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `rentalFromDate` | date-time |  |  |
| `rentalThruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`
- one-nofk [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.product.AssetRental
