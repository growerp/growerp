---
type: Moqui Entity
title: ProductStoreWikiContent
description: "Used to configure the wiki space type and page path given a store content type. An alternative to directly specifying the spaceTypeEnumId (for ProductStoreWikiSpace) and pagePath for lookup within the WikiSpace."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreWikiContent
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreWikiContent

Used to configure the wiki space type and page path given a store content type. An alternative to directly specifying the spaceTypeEnumId (for ProductStoreWikiSpace) and pagePath for lookup within the WikiSpace.

Full entity name: `mantle.product.store.ProductStoreWikiContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storeWikiContentId` | id | Y |  |
| `productStoreId` | id |  |  |
| `contentTypeEnumId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `spaceTypeEnumId` | id |  |  |
| `pagePath` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`
- one `moqui.basic.Enumeration` via `spaceTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreWikiContent
