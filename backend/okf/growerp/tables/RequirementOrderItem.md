---
type: Moqui Entity
title: RequirementOrderItem
description: "Requirement Order Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementOrderItem
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequirementOrderItem

Requirement Order Item

Full entity name: `mantle.request.requirement.RequirementOrderItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Requirement](Requirement.md) via `requirementId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementOrderItem
