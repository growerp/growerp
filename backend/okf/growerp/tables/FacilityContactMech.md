---
type: Moqui Entity
title: FacilityContactMech
description: "Facility Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityContactMech
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityContactMech

Facility Contact Mech

Full entity name: `mantle.facility.FacilityContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `extension` | text-short |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityContactMech
