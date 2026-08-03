---
type: Moqui Entity
title: AssetReservation
description: "Asset Reservation"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetReservation
tags: [mantle, product, issuance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetReservation

Asset Reservation

Full entity name: `mantle.product.issuance.AssetReservation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetReservationId` | id | Y |  |
| `assetId` | id |  |  |
| `productId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `reservationOrderEnumId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `quantityNotAvailable` | number-decimal |  | The quantity not available to promise for this reservation (corresponds to negative Asset.availableToPromiseTotal). |
| `quantityNotIssued` | number-decimal |  | The quantity not yet issued. |
| `reservedDate` | date-time |  |  |
| `originalPromisedDate` | date-time |  |  |
| `currentPromisedDate` | date-time |  |  |
| `priority` | number-integer |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`
- one-nofk [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one `moqui.basic.Enumeration` via `reservationOrderEnumId`
- many [AssetDetail](AssetDetail.md) via `assetReservationId`
- many [AssetIssuance](AssetIssuance.md) via `assetReservationId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetReservation
