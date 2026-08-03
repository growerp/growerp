---
type: Moqui Entity
title: SalesForecast
description: "Sales Forecast"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.forecast.SalesForecast
tags: [mantle, sales, forecast]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SalesForecast

Sales Forecast

Full entity name: `mantle.sales.forecast.SalesForecast`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `salesForecastId` | id | Y |  |
| `parentSalesForecastId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `internalPartyId` | id |  |  |
| `timePeriodId` | id |  |  |
| `currencyUomId` | id |  |  |
| `quotaAmount` | currency-amount |  |  |
| `forecastAmount` | currency-amount |  |  |
| `bestCaseAmount` | currency-amount |  |  |
| `closedAmount` | currency-amount |  |  |
| `percentOfQuotaForecast` | number-decimal |  |  |
| `percentOfQuotaClosed` | number-decimal |  |  |
| `pipelineAmount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent SalesForecast](SalesForecast.md) via `parentSalesForecastId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [Internal Party](Party.md) via `internalPartyId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one `moqui.basic.Uom` via `currencyUomId`
- many [SalesForecastDetail](SalesForecastDetail.md) via `salesForecastId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.forecast.SalesForecast
