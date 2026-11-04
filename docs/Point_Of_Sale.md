# Point of sale

`PosServices100` sells to a shared walk-in customer in one transaction. REST: `Pos/Catalog`,
`Pos/Barcode`, `Pos/Quote`, `Pos/Sale`, `Pos/Receipt` in the `GROWERP_POS` domain.

- **`create#PosSale`**: order on channel `ScPos`, then `finish#PosOrder`: place, invoice, payments,
  approve, stock. `clientSaleId` comes from the terminal: the same id again returns the first sale,
  with other content it is refused.
- **Prices** come from the catalog (`PptCurrent`); the client only sends product and quantity.
- **Tax** is off on the order part while lines are added and calculated once at the end; per line
  it took 9 seconds for 50 lines. With `pricesIncludeTax` see [Sales_Tax.md](Sales_Tax.md).
- **Tenders**: `PiCash`, `PiCreditCard` and others. Only cash can exceed what is left, the rest is
  `changeAmount`. Only what the sale cost is booked. Card payments are recorded, not processed.
- **Stock**: `ship#OrderPart` when a line is tracked in stock, else `complete#Order`. A sale above
  recorded stock still goes through: `record#PhysicalInventoryQuantity` corrects stock first and
  that record is the variance log.
- **Amounts and dates** leave the services as strings, the frontend `Decimal` and
  `DateTimeConverter` cannot read JSON numbers.
- **Walk-in customer**: party with pseudoId `WALKIN` per owner, without Customer role, so it stays
  out of the customer lists. Sales to a named customer are not supported yet.

## Frontend

Block `growerp_pos`: `PosCheckoutScreen` (tiles and cart side by side from 700 wide, stacked below),
`PosTenderDialog`, `PosReceiptDialog`, `buildPosReceipt` for the 80mm PDF. A scanner works as a
keyboard: it types into the search field and presses enter. Barcodes are entered in the product
dialog (`ProductIdentification` of type `PidtEan`).

App `shop` opens on the checkout; the other menu items are for the admin. The `GROWERP_POS` domain
is only granted to companies registered in an app with the checkout on its menu.
