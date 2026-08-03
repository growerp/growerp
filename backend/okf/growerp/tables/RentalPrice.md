---
type: Moqui Entity
title: RentalPrice
description: "Date-banded rental (room) rate for a rental product; when no band matches a date the product current price applies"
resource: http://127.0.0.1:8080/rest/e1/growerp.product.RentalPrice
tags: [growerp, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RentalPrice

Date-banded rental (room) rate for a rental product; when no band matches a date the product current price applies

Full entity name: `growerp.product.RentalPrice`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `rentalPriceId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `productId` | id |  |  |
| `fromDate` | date |  |  |
| `thruDate` | date |  |  |
| `price` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.product.RentalPrice
