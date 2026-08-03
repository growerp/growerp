---
type: Moqui Entity
title: ProductGeo
description: "Product Geo"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductGeo
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductGeo

Product Geo

Full entity name: `mantle.product.ProductGeo`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `geoId` | id | Y |  |
| `productGeoPurposeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.basic.Geo` via `geoId`
- one `moqui.basic.Enumeration` via `productGeoPurposeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductGeo
