---
type: Moqui Entity
title: ProductParameterOption
description: "Product Parameter Option"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterOption
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParameterOption

Product Parameter Option

Full entity name: `mantle.product.ProductParameterOption`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productParameterOptionId` | id | Y |  |
| `productParameterId` | id |  |  |
| `productId` | id |  | Optional, if null option applies to all products that use the ProductParameter |
| `marketSegmentId` | id |  |  |
| `productStoreId` | id |  |  |
| `productUomDimensionId` | id |  | For options associated with a ProductUomDimension |
| `productOtherIdentId` | id |  | For options associated with a ProductOtherIdentification |
| `parameterValue` | text-medium |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductParameter](ProductParameter.md) via `productParameterId`
- one [Product](Product.md) via `productId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [ProductUomDimension](ProductUomDimension.md) via `productUomDimensionId`
- one [ProductOtherIdentification](ProductOtherIdentification.md) via `productOtherIdentId`
- many [ProductParameterValue](ProductParameterValue.md) via `productParameterOptionId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterOption
