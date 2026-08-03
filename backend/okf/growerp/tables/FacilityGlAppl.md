---
type: Moqui Entity
title: FacilityGlAppl
description: "Used to specify relevant GL Accounts for a Facility (expense, revenue, etc); not related to posting conf"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGlAppl
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityGlAppl

Used to specify relevant GL Accounts for a Facility (expense, revenue, etc); not related to posting conf

Full entity name: `mantle.facility.FacilityGlAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `glAccountId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityGlAppl
