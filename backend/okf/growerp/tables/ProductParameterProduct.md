---
type: Moqui Entity
title: ProductParameterProduct
description: "Product Parameter Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterProduct
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParameterProduct

Product Parameter Product

Full entity name: `mantle.product.ProductParameterProduct`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productParameterId` | id | Y |  |
| `productId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductParameter](ProductParameter.md) via `productParameterId`
- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterProduct
