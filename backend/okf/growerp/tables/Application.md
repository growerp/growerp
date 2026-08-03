---
type: Moqui Entity
title: Application
description: "Application"
resource: http://127.0.0.1:8080/rest/e1/growerp.Application
tags: [growerp]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Application

Application

Full entity name: `growerp.Application`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `applicationId` | id | Y |  |
| `description` | text-medium |  |  |
| `version` | text-short |  |  |
| `backendUrl` | text-medium |  |  |
| `assessmentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Assessment](Assessment.md) via `assessmentId`
- many [PartyApplication](PartyApplication.md) via `applicationId`
- many [Application TenantSetup](TenantSetup.md) via `applicationId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.Application
