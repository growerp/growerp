---
type: Moqui Entity
title: ProductReview
description: "Product Review"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.ProductReview
tags: [mantle, product]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductReview

Product Review

Full entity name: `mantle.product.ProductReview`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productReviewId` | id | Y |  |
| `productStoreId` | id |  |  |
| `productId` | id |  |  |
| `userId` | id |  |  |
| `statusId` | id |  |  |
| `postedAnonymous` | text-indicator |  |  |
| `postedDateTime` | date-time |  |  |
| `productRating` | number-decimal |  |  |
| `productReview` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Product](Product.md) via `productId`
- one `moqui.security.UserAccount` via `userId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.ProductReview
