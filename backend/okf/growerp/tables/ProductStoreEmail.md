---
type: Moqui Entity
title: ProductStoreEmail
description: "Product Store Email"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreEmail
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreEmail

Product Store Email

Full entity name: `mantle.product.store.ProductStoreEmail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `emailTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `emailTemplateId` | id |  |  |
| `headerImagePath` | text-medium |  |  |
| `detailLinkPath` | text-medium |  |  |
| `webOrderBcc` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `emailTypeEnumId`
- one `moqui.basic.email.EmailTemplate` via `emailTemplateId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreEmail
