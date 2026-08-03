---
type: Moqui Entity
title: AgreementItemParty
description: "Agreement Item Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemParty
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementItemParty

Agreement Item Party

Full entity name: `mantle.party.agreement.AgreementItemParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementItemSeqId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItemParty
