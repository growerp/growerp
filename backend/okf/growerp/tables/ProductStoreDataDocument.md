---
type: Moqui Entity
title: ProductStoreDataDocument
description: "Relationship between the ProductStore and DataDocument Entities meant to replace ProductStore.productDataDocumentId fields and the like. See: https://forum.moqui.org/t/productstore-datadocument-options/303."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreDataDocument
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreDataDocument

Relationship between the ProductStore and DataDocument Entities meant to replace ProductStore.productDataDocumentId fields and the like. See: https://forum.moqui.org/t/productstore-datadocument-options/303.

Full entity name: `mantle.product.store.ProductStoreDataDocument`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreId` | id | Y |  |
| `typeEnumId` | id | Y |  |
| `dataDocumentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.entity.document.DataDocument` via `dataDocumentId`
- one `moqui.basic.Enumeration` via `typeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreDataDocument
