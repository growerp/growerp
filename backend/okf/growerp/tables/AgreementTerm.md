---
type: Moqui Entity
title: AgreementTerm
description: "Agreement Term"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementTerm
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementTerm

Agreement Term

Full entity name: `mantle.party.agreement.AgreementTerm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementTermId` | id | Y |  |
| `agreementId` | id |  |  |
| `agreementItemSeqId` | id |  |  |
| `settlementTermId` | id |  |  |
| `termTypeEnumId` | id |  |  |
| `termText` | text-long |  |  |
| `termNumber` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Agreement](Agreement.md) via `agreementId`
- one-nofk [AgreementItem](AgreementItem.md) via `agreementId`, `agreementItemSeqId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`
- one `moqui.basic.Enumeration` via `termTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementTerm
