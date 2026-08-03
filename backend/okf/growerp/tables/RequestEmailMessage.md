---
type: Moqui Entity
title: RequestEmailMessage
description: "Request Email Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestEmailMessage
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestEmailMessage

Request Email Message

Full entity name: `mantle.request.RequestEmailMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `emailMessageId` | id | Y |  |
| `partyId` | id |  |  |
| `statusId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one `moqui.basic.email.EmailMessage` via `emailMessageId`
- one [Party](Party.md) via `partyId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestEmailMessage
