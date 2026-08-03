---
type: Moqui Entity
title: ChatRoom
description: "Chat Room"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.ChatRoom
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ChatRoom

Chat Room

Full entity name: `growerp.general.ChatRoom`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `chatRoomId` | id | Y |  |
| `chatRoomName` | text-medium |  |  |
| `isPrivate` | text-indicator |  |  |
| `isActive` | text-indicator |  |  |
| `ownerPartyId` | id |  |  |
| `visitorToken` | text-medium |  |  |
| `visitorUserId` | id |  |  |
| `chatAgentConfigId` | id |  |  |
| `agentActive` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- many [ChatMessage](ChatMessage.md) via `chatRoomId`
- many [Room ChatRoomMember](ChatRoomMember.md) via `chatRoomId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.ChatRoom
