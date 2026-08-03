---
type: Moqui Entity
title: GlAccount
description: "Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccount
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccount

Gl Account

Full entity name: `mantle.ledger.account.GlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `parentGlAccountId` | id |  |  |
| `glAccountTypeEnumId` | id |  | Optional. The 'type' of account, used in posting (GL mapping) configuration |
| `glAccountClassEnumId` | id |  | Required. The account classification such as Revenue, Expense, Asset, etc. Used for report structure and to determine if account is a debit or credit account. |
| `isDebit` | text-indicator |  | Y if account class is a Debit class, otherwise a Credit; determined automatically by class and saved here |
| `isTemporary` | text-indicator |  | Y if account is a temporary (income statement) account, determined automatically by class and saved here |
| `glResourceTypeEnumId` | id |  |  |
| `glXbrlClassEnumId` | id |  |  |
| `accountCode` | text-medium |  |  |
| `accountName` | text-medium |  |  |
| `description` | text-medium |  |  |
| `externalId` | id |  | ID of the account in an external system where the accounts are imported/exported |
| `disallowPosting` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent GlAccount](GlAccount.md) via `parentGlAccountId`
- one `moqui.basic.Enumeration` via `glAccountTypeEnumId`
- one `moqui.basic.Enumeration` via `glAccountClassEnumId`
- one `moqui.basic.Enumeration` via `glResourceTypeEnumId`
- one `moqui.basic.Enumeration` via `glXbrlClassEnumId`
- many [PostTo FinancialAccount](FinancialAccount.md) via `glAccountId`
- many [Override InvoiceItem](InvoiceItem.md) via `glAccountId`
- many [PaymentMethod](PaymentMethod.md) via `glAccountId`
- many [Override Payment](Payment.md) via `glAccountId`
- many [ItemType Payment](Payment.md) via `glAccountId`
- many [Override PaymentApplication](PaymentApplication.md) via `glAccountId`
- many [FacilityGlAppl](FacilityGlAppl.md) via `glAccountId`
- many [Override PayrollAdjustment](PayrollAdjustment.md) via `glAccountId`
- many [Override WorkTypeGlOverride](WorkTypeGlOverride.md) via `glAccountId`
- many [GlAccountCategoryMember](GlAccountCategoryMember.md) via `glAccountId`
- many [GlAccountEnumAppl](GlAccountEnumAppl.md) via `glAccountId`
- many [GlAccountGroupMember](GlAccountGroupMember.md) via `glAccountId`
- many [GlAccountOrgTimePeriod](GlAccountOrgTimePeriod.md) via `glAccountId`
- many [GlAccountOrganization](GlAccountOrganization.md) via `glAccountId`
- many [GlAccountParty](GlAccountParty.md) via `glAccountId`
- many [GlBudgetXref](GlBudgetXref.md) via `glAccountId`
- many [Asset AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [WipAsset AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Receipt AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Issuance AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Depreciation AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Profit AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Loss AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Shrinkage AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [Found AssetTypeGlAccount](AssetTypeGlAccount.md) via `glAccountId`
- many [CreditCardTypeGlAccount](CreditCardTypeGlAccount.md) via `glAccountId`
- many [FinancialAccountReasonGlAccount](FinancialAccountReasonGlAccount.md) via `glAccountId`
- many [FinancialAccountTypeGlAccount](FinancialAccountTypeGlAccount.md) via `glAccountId`
- many [GlAccountTypeDefault](GlAccountTypeDefault.md) via `glAccountId`
- many [GlAccountTypePartyDefault](GlAccountTypePartyDefault.md) via `glAccountId`
- many [InvoiceTypeTransType](InvoiceTypeTransType.md) via `glAccountId`
- many [ItemTypeGlAccount](ItemTypeGlAccount.md) via `glAccountId`
- many [PaymentInstrumentGlAccount](PaymentInstrumentGlAccount.md) via `glAccountId`
- many [PaymentTypeGlAccount](PaymentTypeGlAccount.md) via `glAccountId`
- many [ProductCategoryGlAccount](ProductCategoryGlAccount.md) via `glAccountId`
- many [ProductGlAccount](ProductGlAccount.md) via `glAccountId`
- many [TaxAuthorityGlAccount](TaxAuthorityGlAccount.md) via `glAccountId`
- many [VarianceReasonGlAccount](VarianceReasonGlAccount.md) via `glAccountId`
- many [GlReconciliation](GlReconciliation.md) via `glAccountId`
- many [AcctgTransEntry](AcctgTransEntry.md) via `glAccountId`
- many [Override OrderItem](OrderItem.md) via `glAccountId`
- many [BudgetItem](BudgetItem.md) via `glAccountId`
- many [ProductGlAppl](ProductGlAppl.md) via `glAccountId`
- many [AssetGlAppl](AssetGlAppl.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccount
