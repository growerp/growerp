---
type: Moqui Entity
title: FacilityNote
description: "Facility Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityNote
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityNote

Facility Note

Full entity name: `mantle.facility.FacilityNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `userId` | id |  |  |
| `noteText` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityNote
