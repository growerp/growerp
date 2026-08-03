---
type: Moqui Entity
title: WorkRequirementFulfillment
description: "Work Requirement Fulfillment"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.WorkRequirementFulfillment
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkRequirementFulfillment

Work Requirement Fulfillment

Full entity name: `mantle.request.requirement.WorkRequirementFulfillment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `fulfillmentTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Requirement](Requirement.md) via `requirementId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.basic.Enumeration` via `fulfillmentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.WorkRequirementFulfillment
