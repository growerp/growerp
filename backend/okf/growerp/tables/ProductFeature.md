---
type: Moqui Entity
title: ProductFeature
description: "Product Feature"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeature
tags: [mantle, product, feature]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductFeature

Product Feature

Full entity name: `mantle.product.feature.ProductFeature`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productFeatureId` | id | Y |  |
| `productFeatureTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `numberSpecified` | number-decimal |  |  |
| `numberUomId` | id |  |  |
| `defaultAmount` | currency-amount |  |  |
| `defaultSequenceNum` | number-integer |  |  |
| `abbrev` | id |  |  |
| `idCode` | text-short |  |  |
| `ownerPartyId` | id |  |  |
| `numberPerPallet` | number-decimal |  |  |
| `perPalletTier` | number-decimal |  |  |
| `tiersPerPallet` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productFeatureTypeEnumId`
- one `moqui.basic.Uom` via `numberUomId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [ProductFeatureAppl](ProductFeatureAppl.md) via `productFeatureId`
- many [ProductFeatureIactn](ProductFeatureIactn.md) via `productFeatureId`
- many [ProductFeatureIactn](ProductFeatureIactn.md) via `productFeatureId`
- many [ProductFeatureGroupAppl](ProductFeatureGroupAppl.md) via `productFeatureId`
- many [OrderItem](OrderItem.md) via `productFeatureId`
- many [ProductContent](ProductContent.md) via `productFeatureId`
- many [To ProductFeatureIactn](ProductFeatureIactn.md) via `productFeatureId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.feature.ProductFeature
