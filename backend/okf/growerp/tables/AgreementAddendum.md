---
type: Moqui Entity
title: AgreementAddendum
description: "Agreement Addendum"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementAddendum
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementAddendum

Agreement Addendum

Full entity name: `mantle.party.agreement.AgreementAddendum`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementAddendumId` | id | Y |  |
| `agreementId` | id |  |  |
| `agreementItemSeqId` | id |  |  |
| `addendumCreationDate` | date-time |  |  |
| `addendumEffectiveDate` | date-time |  |  |
| `addendumText` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Agreement](Agreement.md) via `agreementId`
- one [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementAddendum
