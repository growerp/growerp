---
type: Moqui Entity
title: TaxAuthorityCategory
description: "Tax Authority Category"
resource: http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityCategory
tags: [mantle, other, tax]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxAuthorityCategory

Tax Authority Category

Full entity name: `mantle.other.tax.TaxAuthorityCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxAuthorityId` | id | Y |  |
| `productCategoryId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.other.tax.TaxAuthorityCategory
