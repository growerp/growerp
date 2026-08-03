---
type: Moqui Entity
title: AgreementItemEmployment
description: "Agreement Item Employment"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemEmployment
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementItemEmployment

Agreement Item Employment

Full entity name: `mantle.party.agreement.AgreementItemEmployment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementItemSeqId` | id | Y |  |
| `partyRelationshipId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemEmployment
