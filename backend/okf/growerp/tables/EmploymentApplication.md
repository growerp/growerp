---
type: Moqui Entity
title: EmploymentApplication
description: "Employment Application"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentApplication
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentApplication

Employment Application

Full entity name: `mantle.humanres.employment.EmploymentApplication`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `employmentApplicationId` | id | Y |  |
| `emplPositionId` | id |  |  |
| `statusId` | id |  |  |
| `referredByEnumId` | id |  |  |
| `applicationDate` | date-time |  |  |
| `applyingPartyId` | id |  |  |
| `referredByPartyId` | id |  |  |
| `approverPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPosition](EmplPosition.md) via `emplPositionId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Enumeration` via `referredByEnumId`
- one [Applying Party](Party.md) via `applyingPartyId`
- one [ReferredBy Party](Party.md) via `referredByPartyId`
- one [Approver Party](Party.md) via `approverPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentApplication
