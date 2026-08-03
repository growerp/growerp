---
type: Moqui Entity
title: FacilityCertification
description: "Facility Certification"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityCertification
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityCertification

Facility Certification

Full entity name: `mantle.facility.FacilityCertification`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityCertificationId` | id | Y |  |
| `facilityId` | id |  |  |
| `certificationTypeEnumId` | id |  |  |
| `fromDate` | date |  |  |
| `thruDate` | date |  |  |
| `contactPartyId` | id |  |  |
| `auditorPartyId` | id |  |  |
| `auditorOrgPartyId` | id |  |  |
| `auditStartDate` | date-time |  |  |
| `auditEndDate` | date-time |  |  |
| `auditScore` | text-short |  |  |
| `certRegistrationId` | text-short |  |  |
| `otherCertId` | text-short |  |  |
| `documentLocation` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `certificationTypeEnumId`
- one [Contact Party](Party.md) via `contactPartyId`
- one [Auditor Party](Party.md) via `auditorPartyId`
- one [AuditorOrg Party](Party.md) via `auditorOrgPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityCertification
