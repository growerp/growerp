---
type: Moqui Entity
title: FacilityPrinter
description: "Facility Printer"
resource: http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityPrinter
tags: [mantle, facility]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FacilityPrinter

Facility Printer

Full entity name: `mantle.facility.FacilityPrinter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `facilityId` | id | Y |  |
| `printerPurposeEnumId` | id | Y |  |
| `networkPrinterId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Facility](Facility.md) via `facilityId`
- one `moqui.basic.Enumeration` via `printerPurposeEnumId`
- one `moqui.basic.print.NetworkPrinter` via `networkPrinterId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.facility.FacilityPrinter
