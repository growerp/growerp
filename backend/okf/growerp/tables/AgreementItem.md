---
type: Moqui Entity
title: AgreementItem
description: "For price lists associated with an AgreementItem use the ProducePrice entity."
resource: http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItem
tags: [mantle, party, agreement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AgreementItem

For price lists associated with an AgreementItem use the ProducePrice entity.

Full entity name: `mantle.party.agreement.AgreementItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `agreementId` | id | Y |  |
| `agreementItemSeqId` | id | Y |  |
| `agreementItemTypeEnumId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `productId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `itemText` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Agreement](Agreement.md) via `agreementId`
- one `moqui.basic.Enumeration` via `agreementItemTypeEnumId`
- one [Product](Product.md) via `productId`
- one `moqui.basic.Uom` via `quantityUomId`
- many [AgreementTerm](AgreementTerm.md) via `agreementId`, `agreementItemSeqId`
- many [AgreementAddendum](AgreementAddendum.md) via `agreementId`, `agreementItemSeqId`
- many [AgreementItemEmployment](AgreementItemEmployment.md) via `agreementId`, `agreementItemSeqId`
- many [AgreementItemGeo](AgreementItemGeo.md) via `agreementId`, `agreementItemSeqId`
- many [AgreementItemParty](AgreementItemParty.md) via `agreementId`, `agreementItemSeqId`
- many [AgreementItemWorkEffort](AgreementItemWorkEffort.md) via `agreementId`, `agreementItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.agreement.AgreementItem
