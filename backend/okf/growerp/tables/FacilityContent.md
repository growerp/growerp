---
type: Moqui Entity
title: FacilityContent
description: "Facility Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityContent
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityContent

Facility Content

Full entity name: `mantle.facility.FacilityContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityContentId` | id | Y |  |
| `facilityId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `facilityContentTypeEnumId` | id |  |  |
| `contentDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `facilityContentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityContent
