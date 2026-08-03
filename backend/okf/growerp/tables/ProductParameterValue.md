---
type: Moqui Entity
title: ProductParameterValue
description: "Product Parameter Value"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterValue
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductParameterValue

Product Parameter Value

Full entity name: `mantle.product.ProductParameterValue`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productParameterValueId` | id | Y |  |
| `productParameterId` | id |  |  |
| `productParameterSetId` | id |  |  |
| `marketSegmentId` | id |  | Specify if parameterValue is based on customer's inclusion in a MarketSegment |
| `productParameterOptionId` | id |  | For values that come from a ProductParameterOption |
| `parameterValue` | text-medium |  |  |
| `uomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductParameterSet](ProductParameterSet.md) via `productParameterSetId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`
- one [ProductParameter](ProductParameter.md) via `productParameterId`
- one [ProductParameterOption](ProductParameterOption.md) via `productParameterOptionId`
- one `moqui.basic.Uom` via `uomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductParameterValue
