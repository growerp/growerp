---
type: Moqui Entity
title: ProductParameter
description: "Parameters for personalization and other information to track with purchase of Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameter
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParameter

Parameters for personalization and other information to track with purchase of Product

Full entity name: `mantle.product.ProductParameter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productParameterId` | id | Y |  |
| `description` | text-medium |  |  |
| `uomDimensionTypeId` | id |  | Optional dimension type |
| `productIdTypeEnumId` | id |  | Optional product ID type |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`
- one `moqui.basic.Enumeration` via `productIdTypeEnumId`
- many [ProductParameterOption](ProductParameterOption.md) via `productParameterId`
- many [ProductParameterProduct](ProductParameterProduct.md) via `productParameterId`
- many [ProductParameterValue](ProductParameterValue.md) via `productParameterId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameter
