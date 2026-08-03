---
type: Moqui Entity
title: ProductFeatureAppl
description: "Product Feature Appl"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureAppl
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFeatureAppl

Product Feature Appl

Full entity name: `mantle.product.feature.ProductFeatureAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `productFeatureId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `applTypeEnumId` | id |  |  |
| `sequenceNum` | number-integer |  |  |
| `amount` | number-decimal |  |  |
| `recurringAmount` | number-decimal |  |  |
| `featureProductId` | id |  | For Optional features represented by a Product (lightweight product configuration) |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [ProductFeature](ProductFeature.md) via `productFeatureId`
- one `moqui.basic.Enumeration` via `applTypeEnumId`
- one [Feature Product](Product.md) via `featureProductId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeatureAppl
