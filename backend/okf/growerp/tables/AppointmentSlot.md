---
type: Moqui Entity
title: AppointmentSlot
description: "A bookable time slot offered by the company; booking creates a WorkEffort event (workEffortId) with the lead as attendee."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.AppointmentSlot
tags: [growerp, marketing]
timestamp: 2026-07-12T22:46:49.215378774Z
---

# AppointmentSlot

A bookable time slot offered by the company; booking creates a WorkEffort event (workEffortId) with the lead as attendee.

Full entity name: `growerp.marketing.AppointmentSlot`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `slotId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `startDateTime` | date-time |  |  |
| `endDateTime` | date-time |  |  |
| `status` | text-short |  |  |
| `workEffortId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.AppointmentSlot
