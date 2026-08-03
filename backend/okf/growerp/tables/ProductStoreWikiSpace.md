---
type: Moqui Entity
title: ProductStoreWikiSpace
description: "Used to configure a WikiSpace to use for a given store, space type, and locale instead of directly referencing a wikiSpaceId."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreWikiSpace
tags: [mantle, product, store]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductStoreWikiSpace

Used to configure a WikiSpace to use for a given store, space type, and locale instead of directly referencing a wikiSpaceId.

Full entity name: `mantle.product.store.ProductStoreWikiSpace`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `storeWikiSpaceId` | id | Y |  |
| `productStoreId` | id |  |  |
| `spaceTypeEnumId` | id |  |  |
| `locale` | text-short |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `wikiSpaceId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `spaceTypeEnumId`
- one `moqui.resource.wiki.WikiSpace` via `wikiSpaceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.store.ProductStoreWikiSpace
