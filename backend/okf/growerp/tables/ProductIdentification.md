---
type: Moqui Entity
title: ProductIdentification
description: "Product Identification"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductIdentification
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductIdentification

Product Identification

Full entity name: `mantle.product.ProductIdentification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `productIdTypeEnumId` | id | Y |  |
| `idValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productIdTypeEnumId`
- one [Product](Product.md) via `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductIdentification
