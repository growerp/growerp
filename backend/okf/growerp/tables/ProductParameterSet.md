---
type: Moqui Entity
title: ProductParameterSet
description: "Used to group a set of parameter values for reference by single ID used on OrderItem, etc"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterSet
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParameterSet

Used to group a set of parameter values for reference by single ID used on OrderItem, etc

Full entity name: `mantle.product.ProductParameterSet`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productParameterSetId` | id | Y |  |
| `comments` | text-medium |  |  |
| `productId` | id |  |  |
| `customerPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [Customer Party](Party.md) via `customerPartyId`
- many [OrderItem](OrderItem.md) via `productParameterSetId`
- many [ProductParameterValue](ProductParameterValue.md) via `productParameterSetId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterSet
