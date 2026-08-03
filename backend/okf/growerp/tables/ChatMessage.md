---
type: Moqui Entity
title: ChatMessage
description: "Chat Message"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.ChatMessage
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ChatMessage

Chat Message

Full entity name: `growerp.general.ChatMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `chatMessageId` | id | Y |  |
| `content` | text-very-long |  |  |
| `chatRoomId` | id |  |  |
| `fromUserId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.security.UserAccount` via `fromUserId`
- one [ChatRoom](ChatRoom.md) via `chatRoomId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.ChatMessage
