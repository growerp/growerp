---
type: Moqui Entity
title: Requirement
description: "Requirement"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.Requirement
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Requirement

Requirement

Full entity name: `mantle.request.requirement.Requirement`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `requirementTypeEnumId` | id |  |  |
| `statusId` | id |  |  |
| `facilityId` | id |  |  |
| `deliverableId` | id |  |  |
| `assetId` | id |  |  |
| `productId` | id |  |  |
| `description` | text-medium |  |  |
| `requirementStartDate` | date-time |  |  |
| `requiredByDate` | date-time |  |  |
| `estimatedBudget` | currency-amount |  |  |
| `quantity` | number-decimal |  |  |
| `useCase` | text-very-long |  |  |
| `reason` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `requirementTypeEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Facility](Facility.md) via `facilityId`
- one [Deliverable](Deliverable.md) via `deliverableId`
- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`
- many [RequirementBudgetAllocation](RequirementBudgetAllocation.md) via `requirementId`
- many [RequirementOrderItem](RequirementOrderItem.md) via `requirementId`
- many [RequirementParty](RequirementParty.md) via `requirementId`
- many [RequirementRequestItem](RequirementRequestItem.md) via `requirementId`
- many [WorkRequirementFulfillment](WorkRequirementFulfillment.md) via `requirementId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.Requirement
