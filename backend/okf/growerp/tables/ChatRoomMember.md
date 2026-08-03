---
type: Moqui Entity
title: ChatRoomMember
description: "Chat Room Member"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.ChatRoomMember
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ChatRoomMember

Chat Room Member

Full entity name: `growerp.general.ChatRoomMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `chatRoomId` | id | Y |  |
| `userId` | id | Y |  |
| `isActive` | text-indicator |  |  |
| `hasRead` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.security.UserAccount` via `userId`
- one [Room ChatRoom](ChatRoom.md) via `chatRoomId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.ChatRoomMember
