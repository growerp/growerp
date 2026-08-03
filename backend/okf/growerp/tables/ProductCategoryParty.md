---
type: Moqui Entity
title: ProductCategoryParty
description: "Product Category Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryParty
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategoryParty

Product Category Party

Full entity name: `mantle.product.category.ProductCategoryParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategoryParty
