---
type: Moqui Entity
title: RoleGroupMember
description: "Role Group Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.RoleGroupMember
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RoleGroupMember

Role Group Member

Full entity name: `mantle.party.RoleGroupMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `roleGroupEnumId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `roleGroupEnumId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.RoleGroupMember
