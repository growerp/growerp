---
type: Moqui Entity
title: Agreement
description: "Agreement"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.Agreement
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Agreement

Agreement

Full entity name: `mantle.party.agreement.Agreement`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementTypeEnumId` | id |  |  |
| `statusId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `organizationRoleTypeId` | id |  |  |
| `otherPartyId` | id |  |  |
| `otherRoleTypeId` | id |  |  |
| `agreementDate` | date-time |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `description` | text-medium |  |  |
| `currencyUomId` | id |  |  |
| `isTemplate` | text-indicator |  |  |
| `templateAgreementId` | id |  | The template agreement this agreement was cloned from |
| `textData` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `agreementTypeEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [Organization RoleType](RoleType.md) via `organizationRoleTypeId`
- one [Other Party](Party.md) via `otherPartyId`
- one [Other RoleType](RoleType.md) via `otherRoleTypeId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [Template Agreement](Agreement.md) via `templateAgreementId`
- many [AgreementTerm](AgreementTerm.md) via `agreementId`
- many [AgreementItem](AgreementItem.md) via `agreementId`
- many [AgreementParty](AgreementParty.md) via `agreementId`
- many [AgreementAddendum](AgreementAddendum.md) via `agreementId`
- many [AgreementAssoc](AgreementAssoc.md) via `agreementId`
- many [To AgreementAssoc](AgreementAssoc.md) via `agreementId`
- many [AgreementContent](AgreementContent.md) via `agreementId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.Agreement
