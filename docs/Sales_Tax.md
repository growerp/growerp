# Sales tax

A company without tax rates charges no tax. Adding a rate under Accounting > Ledger > Tax Rates
(`TaxRateList`) switches tax on for all its sales orders and sales invoices.

- **Rates**: `growerp.tax.TaxRate`, per owner. The rate without a category is the default; a rate
  with a product category beats it. `fromDate`/`thruDate` limit a rate in time.
- **Not taxed**: purchase documents, products with `taxable=N`, and customers with a
  `TaxAuthorityParty` row with `isExempt=Y`. Shipping only when the rate has `taxShipping`.
- **Orders**: mantle calls the `LOCAL` tax gateway on every order change, which runs
  `TaxServices100.calculate#SalesTaxGrowerp` and adds `ItemSalesTax` lines. The invoice of an order
  copies them.
- **Stand-alone invoices**: `calculate#InvoiceTax` runs after the items are saved.
- **Tax lines entered by hand** stay as long as the company has no rates; with rates, tax lines are
  always calculated.
- **Prices with tax included** (`ProductStore.pricesIncludeTax`) apply to orders of the POS channel
  (`ScPos`) only: `calculate#NetUnitAmount` gives the net amount for the line, `unitListPrice` holds
  the shelf price and tax is the difference. Other orders keep tax on top, so on such a store a
  catalog price used on a back-office order is taxed again.

Mantle's `TaxAuthorityRate` entity is commented out, which is why rates have an entity of their own.
