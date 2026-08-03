---
type: Moqui Entity
title: ProductClassFeature
description: "Product Class Feature"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassFeature
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductClassFeature

Product Class Feature

Full entity name: `mantle.product.ProductClassFeature`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productClassEnumId` | id | Y |  |
| `productFeatureTypeEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productClassEnumId`
- one `moqui.basic.Enumeration` via `productFeatureTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassFeature
