---
type: Moqui Entity
title: EmploymentLeave
description: "Employment Leave"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentLeave
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentLeave

Employment Leave

Full entity name: `mantle.humanres.employment.EmploymentLeave`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `fromDate` | date | Y |  |
| `thruDate` | date |  |  |
| `leaveTypeEnumId` | id |  |  |
| `leaveReasonEnumId` | id |  |  |
| `leaveApproved` | text-indicator |  |  |
| `approverPartyId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one `moqui.basic.Enumeration` via `leaveTypeEnumId`
- one `moqui.basic.Enumeration` via `leaveReasonEnumId`
- one [Approver Party](Party.md) via `approverPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentLeave
