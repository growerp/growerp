---
type: Moqui Entity
title: ProductParty
description: "Product Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParty
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParty

Product Party

Full entity name: `mantle.product.ProductParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `sequenceNum` | number-integer |  |  |
| `comments` | text-medium |  |  |
| `otherPartyItemName` | text-medium |  |  |
| `otherPartyItemId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParty
