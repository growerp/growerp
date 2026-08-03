---
type: Moqui Entity
title: ProductOtherIdentification
description: "Product Other Identification"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductOtherIdentification
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductOtherIdentification

Product Other Identification

Full entity name: `mantle.product.ProductOtherIdentification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productOtherIdentId` | id | Y |  |
| `productId` | id |  |  |
| `productStoreId` | id |  |  |
| `productIdTypeEnumId` | id |  |  |
| `marketSegmentId` | id |  |  |
| `parentProductId` | id |  |  |
| `idValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productIdTypeEnumId`
- one [Product](Product.md) via `productId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one [Parent Product](Product.md) via `parentProductId`
- many [ProductParameterOption](ProductParameterOption.md) via `productOtherIdentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductOtherIdentification
