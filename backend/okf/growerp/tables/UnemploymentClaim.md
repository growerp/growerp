---
type: Moqui Entity
title: UnemploymentClaim
description: "Unemployment Claim"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.UnemploymentClaim
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# UnemploymentClaim

Unemployment Claim

Full entity name: `mantle.humanres.employment.UnemploymentClaim`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `unemploymentClaimId` | id | Y |  |
| `unemploymentClaimDate` | date-time |  |  |
| `partyRelationshipId` | id |  |  |
| `statusId` | id |  |  |
| `description` | text-medium |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.UnemploymentClaim
