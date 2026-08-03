---
type: Moqui Entity
title: Employment
description: "This is a type of PartyRelationship so shares the ID with the related PartyRelationship record between employee (fromPartyId) and internal organization (toPartyId) with relationshipTypeEnumId=PrtEmployee."
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.Employment
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Employment

This is a type of PartyRelationship so shares the ID with the related PartyRelationship record between employee (fromPartyId) and internal organization (toPartyId) with relationshipTypeEnumId=PrtEmployee.

Full entity name: `mantle.humanres.employment.Employment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `emplPositionId` | id |  |  |
| `terminationReasonEnumId` | id |  |  |
| `terminationTypeEnumId` | id |  |  |
| `identityTypeEnumId` | id |  |  |
| `emplAuthzTypeEnumId` | id |  |  |
| `timePeriodTypeId` | id |  | Payroll time period |
| `taxWorkContactMechId` | id |  |  |
| `taxFederalAllowances` | number-integer |  |  |
| `taxStateAllowances` | number-integer |  |  |
| `taxFormId` | id |  |  |
| `taxClassificationEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PartyRelationship](PartyRelationship.md) via `partyRelationshipId`
- one [EmplPosition](EmplPosition.md) via `emplPositionId`
- one `moqui.basic.Enumeration` via `terminationReasonEnumId`
- one `moqui.basic.Enumeration` via `terminationTypeEnumId`
- one `moqui.basic.Enumeration` via `identityTypeEnumId`
- one `moqui.basic.Enumeration` via `emplAuthzTypeEnumId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`
- one [TaxWork PostalAddress](PostalAddress.md) via `taxWorkContactMechId`
- many [Invoice](Invoice.md) via `partyRelationshipId`
- many [Payment](Payment.md) via `partyRelationshipId`
- many [EmploymentBenefit](EmploymentBenefit.md) via `partyRelationshipId`
- many [EmploymentLeave](EmploymentLeave.md) via `partyRelationshipId`
- many [EmploymentPayHistory](EmploymentPayHistory.md) via `partyRelationshipId`
- many [EmploymentSalary](EmploymentSalary.md) via `partyRelationshipId`
- many [PayrollAdjustment](PayrollAdjustment.md) via `partyRelationshipId`
- many [UnemploymentClaim](UnemploymentClaim.md) via `partyRelationshipId`
- many [TaxStatement](TaxStatement.md) via `partyRelationshipId`
- many [AgreementItemEmployment](AgreementItemEmployment.md) via `partyRelationshipId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.Employment
