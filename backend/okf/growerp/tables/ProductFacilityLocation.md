---
type: Moqui Entity
title: ProductFacilityLocation
description: "Product Facility Location"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.ProductFacilityLocation
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFacilityLocation

Product Facility Location

Full entity name: `mantle.facility.ProductFacilityLocation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `facilityId` | id | Y |  |
| `locationSeqId` | id | Y |  |
| `minimumStock` | number-decimal |  |  |
| `moveQuantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [FacilityLocation](FacilityLocation.md) via `facilityId`, `locationSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.ProductFacilityLocation
