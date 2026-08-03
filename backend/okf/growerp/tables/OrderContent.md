---
type: Moqui Entity
title: OrderContent
description: "Order Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderContent
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderContent

Order Content

Full entity name: `mantle.order.OrderContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderContentId` | id | Y |  |
| `orderContentTypeEnumId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `partyId` | id |  | The Party the content is for |
| `roleTypeId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `viewedDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `orderContentTypeEnumId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one-nofk [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderContent
