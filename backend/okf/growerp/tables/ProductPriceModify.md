---
type: Moqui Entity
title: ProductPriceModify
description: "Product Price Modify"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductPriceModify
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductPriceModify

Product Price Modify

Full entity name: `mantle.product.ProductPriceModify`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `priceModifyId` | id | Y |  |
| `serviceRegisterId` | id |  | Registered Service of type ProductPriceModify that implements the mantle.product.PriceServices.modify#ProductPrice interface |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.service.ServiceRegister` via `serviceRegisterId`
- many [ProductPriceModifyParameter](ProductPriceModifyParameter.md) via `priceModifyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductPriceModify
