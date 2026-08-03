---
type: Moqui Entity
title: ProductClassContent
description: "Product Class Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassContent
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductClassContent

Product Class Content

Full entity name: `mantle.product.ProductClassContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productClassEnumId` | id | Y |  |
| `productContentTypeEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `productClassEnumId`
- one `moqui.basic.Enumeration` via `productContentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductClassContent
