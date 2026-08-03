---
type: Moqui Entity
title: WorkTypeRiskClass
description: "Work Type Risk Class"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.WorkTypeRiskClass
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkTypeRiskClass

Work Type Risk Class

Full entity name: `mantle.humanres.employment.WorkTypeRiskClass`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `geoId` | id | Y |  |
| `workTypeEnumId` | id | Y |  |
| `riskClassEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `workTypeEnumId`
- one `moqui.basic.Enumeration` via `riskClassEnumId`
- one `moqui.basic.Geo` via `geoId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.WorkTypeRiskClass
