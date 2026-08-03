---
type: Moqui Entity
title: OrderItemFormResponse
description: "Order Item Form Response"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemFormResponse
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderItemFormResponse

Order Item Form Response

Full entity name: `mantle.order.OrderItemFormResponse`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `formResponseId` | id | Y |  |
| `partyId` | id |  | The Party who the FormResponse information is for or about |
| `roleTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one `moqui.screen.form.FormResponse` via `formResponseId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemFormResponse
