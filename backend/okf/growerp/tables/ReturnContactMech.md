---
type: Moqui Entity
title: ReturnContactMech
description: "Return Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnContactMech
tags: [mantle, order, return]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ReturnContactMech

Return Contact Mech

Full entity name: `mantle.order.return.ReturnContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `returnId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ReturnHeader](ReturnHeader.md) via `returnId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnContactMech
