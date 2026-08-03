---
type: Moqui Entity
title: TenantSetup
description: "Tenant Setup"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.TenantSetup
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TenantSetup

Tenant Setup

Full entity name: `growerp.general.TenantSetup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `ownerPartyId` | id | Y |  |
| `setupComplete` | text-indicator |  | Y if tenant setup is complete, N otherwise |
| `setupCompletedDate` | date-time |  |  |
| `applicationId` | id |  | The app classification (e.g., AppAdmin, AppHotel) used during registration |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- one [Application Application](Application.md) via `applicationId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.TenantSetup
