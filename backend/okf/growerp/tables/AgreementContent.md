---
type: Moqui Entity
title: AgreementContent
description: "Agreement Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementContent
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementContent

Agreement Content

Full entity name: `mantle.party.agreement.AgreementContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementContentId` | id | Y |  |
| `agreementId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Agreement](Agreement.md) via `agreementId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementContent
