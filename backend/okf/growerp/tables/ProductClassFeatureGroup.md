---
type: Moqui Entity
title: ProductClassFeatureGroup
description: "Product Class Feature Group"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassFeatureGroup
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductClassFeatureGroup

Product Class Feature Group

Full entity name: `mantle.product.ProductClassFeatureGroup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productClassEnumId` | id | Y |  |
| `productFeatureGroupId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productClassEnumId`
- one [ProductFeatureGroup](ProductFeatureGroup.md) via `productFeatureGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassFeatureGroup
