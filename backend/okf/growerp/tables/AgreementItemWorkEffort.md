---
type: Moqui Entity
title: AgreementItemWorkEffort
description: "Agreement Item Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemWorkEffort
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementItemWorkEffort

Agreement Item Work Effort

Full entity name: `mantle.party.agreement.AgreementItemWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementItemSeqId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemWorkEffort
