---
type: Moqui Entity
title: ProductStoreContent
description: "Product Store Content"
resource: http://127.0.0.1:8080/rest/e1/growerp.store.ProductStoreContent
tags: [growerp, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreContent

Product Store Content

Full entity name: `growerp.store.ProductStoreContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productStoreContentId` | id | Y |  |
| `productStoreId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.store.ProductStoreContent
