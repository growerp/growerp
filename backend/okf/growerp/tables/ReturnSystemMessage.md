---
type: Moqui Entity
title: ReturnSystemMessage
description: "Return System Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnSystemMessage
tags: [mantle, order, return]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ReturnSystemMessage

Return System Message

Full entity name: `mantle.order.return.ReturnSystemMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `returnId` | id | Y |  |
| `systemMessageId` | id | Y |  |
| `externalId` | text-short |  |  |
| `originId` | text-short |  |  |
| `displayId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ReturnHeader](ReturnHeader.md) via `returnId`
- one `moqui.service.message.SystemMessage` via `systemMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnSystemMessage
