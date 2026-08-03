---
type: Moqui Entity
title: ProductDbForm
description: "Product Db Form"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductDbForm
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductDbForm

Product Db Form

Full entity name: `mantle.product.ProductDbForm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productDbFormId` | id | Y |  |
| `productId` | id |  |  |
| `formId` | id |  |  |
| `productFormTypeEnumId` | id |  |  |
| `sequenceNum` | number-integer |  |  |
| `roleTypeId` | id |  |  |
| `marketSegmentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.screen.form.DbForm` via `formId`
- one `moqui.basic.Enumeration` via `productFormTypeEnumId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one [MarketSegment](MarketSegment.md) via `marketSegmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductDbForm
