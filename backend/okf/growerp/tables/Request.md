---
type: Moqui Entity
title: Request
description: "Request"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.Request
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Request

Request

Full entity name: `mantle.request.Request`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `requestTypeEnumId` | id |  |  |
| `requestCategoryId` | id |  |  |
| `statusId` | id |  |  |
| `requestName` | text-medium |  |  |
| `description` | text-long |  |  |
| `priority` | number-integer |  |  |
| `requestDate` | date-time |  |  |
| `responseRequiredDate` | date-time |  |  |
| `requestResolutionEnumId` | id |  |  |
| `rootWorkEffortId` | id |  |  |
| `facilityId` | id |  |  |
| `productStoreId` | id |  |  |
| `salesChannelEnumId` | id |  |  |
| `emailContactMechId` | id |  | Where to send the results of the request. |
| `maximumAmountUomId` | id |  |  |
| `currencyUomId` | id |  |  |
| `filedByPartyId` | id |  |  |
| `visitId` | id |  |  |
| `requestPseudoId` | id |  |  |
| `requestOwnerPartyId` | id |  | The company owner, to separate companies. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `requestTypeEnumId`
- one [RequestCategory](RequestCategory.md) via `requestCategoryId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Enumeration` via `requestResolutionEnumId`
- one [Root WorkEffort](WorkEffort.md) via `rootWorkEffortId`
- one [Facility](Facility.md) via `facilityId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one `moqui.basic.Enumeration` via `salesChannelEnumId`
- one [Email ContactMech](ContactMech.md) via `emailContactMechId`
- one `moqui.basic.Uom` via `maximumAmountUomId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [FiledBy Party](Party.md) via `filedByPartyId`
- many [RequestWorkEffort](RequestWorkEffort.md) via `requestId`
- many [RequestParty](RequestParty.md) via `requestId`
- one `moqui.server.Visit` via `visitId`
- many [RequestCommEvent](RequestCommEvent.md) via `requestId`
- many [RequestItem](RequestItem.md) via `requestId`
- many [RequestNote](RequestNote.md) via `requestId`
- many [RequestParty](RequestParty.md) via `requestId`
- many [RequestWorkEffort](RequestWorkEffort.md) via `requestId`
- many [WikiPageRequest](WikiPageRequest.md) via `requestId`
- one [Owner Party](Party.md) via `requestOwnerPartyId`
- many [RequestContent](RequestContent.md) via `requestId`
- many [RequestEmailMessage](RequestEmailMessage.md) via `requestId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.Request
