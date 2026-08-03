---
type: Moqui Entity
title: AssetTypeGlAccount
description: "Found by assetId, then by assetTypeEnumId and classEnumId, then by just assetTypeEnumId"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.AssetTypeGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetTypeGlAccount

Found by assetId, then by assetTypeEnumId and classEnumId, then by just assetTypeEnumId

Full entity name: `mantle.ledger.config.AssetTypeGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetTypeGlAccountId` | id | Y |  |
| `assetTypeEnumId` | id |  |  |
| `classEnumId` | id |  |  |
| `assetId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `assetGlAccountId` | id |  | The debit account for the asset value (purchase cost) on receipt and credit account on issuance; for inventory assets this is the inventory value account (GatInventory); for fixed assets this is a fixed asset value account (GatFixedAsset); for supplies this is an expense account (GatExpense or GatOperatingExpense) |
| `wipAssetGlAccountId` | id |  | The debit account for the asset value (purchase cost) on issue to production run (inventory consumed). The credit account on receive from production run (inventory produced). The opposing account will be the assetGlAccountId. |
| `receiptGlAccountId` | id |  | The credit account on receipt (Unreceived Inventory, Unreceived Asset, etc) |
| `issuanceGlAccountId` | id |  | The debit account on issuance AND credit account for accumulated depreciation for fixed assets; for inventory assets this is the COGS account (GatCogs); for fixed assets this is the Unissued Asset account (GatUnissuedFixedAsset) |
| `transferGlAccountId` | id |  | The credit account on for inventory being transferred (in transit), used instead of receipt and issuance accounts for transfer shipments, etc |
| `accDepreciationGlAccountId` | id |  | The credit account for the depreciation expense for Fixed Assets (paired with depreciationGlAccountId); A debit account for Fixed Asset sale or write off |
| `depreciationGlAccountId` | id |  | The debit account for the depreciation expense for Fixed Assets (paired with accDepreciationGlAccountId) |
| `profitGlAccountId` | id |  | The credit account for the eventual profit/gain derived from the sale of the asset; for inventory assets this is a Sales account; for fixed assets this is a profit/gain on sale/disposal account |
| `lossGlAccountId` | id |  | The debit account for the loss derived from the disposal of the asset |
| `receiptTransTypeEnumId` | id |  |  |
| `issuanceTransTypeEnumId` | id |  |  |
| `shrinkageGlAccountId` | id |  | The debit account for the loss (or cost) for inventory shrinkage or lost fixed assets |
| `foundGlAccountId` | id |  | The credit account for the gain from inventory or fixed assets found |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `assetTypeEnumId`
- one `moqui.basic.Enumeration` via `classEnumId`
- one [Asset](Asset.md) via `assetId`
- one [Party](Party.md) via `organizationPartyId`
- one [Asset GlAccount](GlAccount.md) via `assetGlAccountId`
- one [WipAsset GlAccount](GlAccount.md) via `wipAssetGlAccountId`
- one [Receipt GlAccount](GlAccount.md) via `receiptGlAccountId`
- one [Issuance GlAccount](GlAccount.md) via `issuanceGlAccountId`
- one [Depreciation GlAccount](GlAccount.md) via `depreciationGlAccountId`
- one [Profit GlAccount](GlAccount.md) via `profitGlAccountId`
- one [Loss GlAccount](GlAccount.md) via `lossGlAccountId`
- one `moqui.basic.Enumeration` via `receiptTransTypeEnumId`
- one `moqui.basic.Enumeration` via `issuanceTransTypeEnumId`
- one [Shrinkage GlAccount](GlAccount.md) via `shrinkageGlAccountId`
- one [Found GlAccount](GlAccount.md) via `foundGlAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.AssetTypeGlAccount
