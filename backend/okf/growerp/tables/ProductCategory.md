---
type: Moqui Entity
title: ProductCategory
description: "Product Category"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategory
tags: [mantle, product, category]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductCategory

Product Category

Full entity name: `mantle.product.category.ProductCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productCategoryId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `productCategoryTypeEnumId` | id |  |  |
| `categoryName` | text-medium |  |  |
| `description` | text-very-long |  |  |
| `ownerPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productCategoryTypeEnumId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [ProductCategoryContent](ProductCategoryContent.md) via `productCategoryId`
- many [ProductCategoryParty](ProductCategoryParty.md) via `productCategoryId`
- many [ProductCategoryIdent](ProductCategoryIdent.md) via `productCategoryId`
- many [ProductCategoryMember](ProductCategoryMember.md) via `productCategoryId`
- many [ProductCategoryRollup](ProductCategoryRollup.md) via `productCategoryId`
- many [ProductCategoryRollup](ProductCategoryRollup.md) via `productCategoryId`
- many [ProductCategoryFeatGrpAppl](ProductCategoryFeatGrpAppl.md) via `productCategoryId`
- many [ProductStoreCategory](ProductStoreCategory.md) via `productCategoryId`
- many [ProductCategoryGlAccount](ProductCategoryGlAccount.md) via `productCategoryId`
- many [MarketInterest](MarketInterest.md) via `productCategoryId`
- many [OrderItem](OrderItem.md) via `productCategoryId`
- many [TaxAuthorityCategory](TaxAuthorityCategory.md) via `productCategoryId`
- many [Parent ProductCategoryRollup](ProductCategoryRollup.md) via `productCategoryId`
- many [SalesForecastDetail](SalesForecastDetail.md) via `productCategoryId`
- many [PartyNeed](PartyNeed.md) via `productCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.category.ProductCategory
