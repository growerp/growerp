---
type: Moqui Entity
title: ProductFacility
description: "Product Facility"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.ProductFacility
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFacility

Product Facility

Full entity name: `mantle.facility.ProductFacility`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `facilityId` | id | Y |  |
| `minimumStock` | number-decimal |  |  |
| `reorderQuantity` | number-decimal |  |  |
| `daysToShip` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Facility](Facility.md) via `facilityId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.ProductFacility
