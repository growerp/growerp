# Point of sale

`PosServices100` sells to a shared walk-in customer in one transaction. REST: `PosCatalog`,
`PosBarcode`, `PosQuote`, `PosSale`, `PosReceipt` in the `GROWERP_POS` domain. Resources stay top level: Moqui checks REST authz only on the last
resource of a path, a nested one (`Pos/Shift`) was never checked.

- **`create#PosSale`**: order on channel `ScPos`, then `finish#PosOrder`: place, invoice, payments,
  approve, stock. `clientSaleId` comes from the terminal: the same id again returns the first sale,
  with other content it is refused.
- **Prices** come from the catalog (`PptCurrent`); the client only sends product and quantity.
- **Tax** is off on the order part while lines are added and calculated once at the end; per line
  it took 9 seconds for 50 lines. With `pricesIncludeTax` see [Sales_Tax.md](Sales_Tax.md).
- **Quote and sale** use the same `TaxServices100.calculate#LineTax` as the tax gateway. A sale whose
  booked total differs from the quote is refused, like one for an exempt customer: the POS does not
  know exemptions yet.
- **Tenders**: `PiCash`, `PiCreditCard` and others. Only cash can exceed what is left, the rest is
  `changeAmount`. Only what the sale cost is booked. Card payments are recorded, not processed.
- **Stock**: `ship#OrderPart` when a line is tracked in stock, else `complete#Order`. A sale above
  recorded stock still goes through: `record#PhysicalInventoryQuantity` corrects stock first and
  that record is the variance log.
- **Amounts and dates** leave the services as strings, the frontend `Decimal` and
  `DateTimeConverter` cannot read JSON numbers.
- **Walk-in customer**: party with pseudoId `WALKIN` per owner, without Customer role, so it stays
  out of the customer lists. Sales to a named customer are not supported yet.

## Refunds

`create#PosRefund` gives money back for lines of a sale, for an admin only, in one transaction:
mantle return with the tax prorated, credit memo (`InvoiceReturn`), refund payment, stock back when
`restock` is set. The money goes back by the first tender of the sale unless `method` says otherwise.
`clientRefundId` works like `clientSaleId`. Lookup by the invoice number on the receipt:
`get#PosSaleLookup` also gives what can still be returned per line. Restocked goods go back on
quantity only, the cost of goods is not reversed in the ledger.

## Shifts

A till sells only with an open shift (`PosShift`, one open per `terminalName`): sales and refunds
are refused otherwise and carry the `shiftId`. The device keeps its till name in `posTerminal`.
`close#Shift` takes the counted cash; expected is float + cash sales - cash refunds + movements.
A difference is posted through the cash book: short on `789000000` Misc Operating Expense, over on
`86000` Write Off Income. `PosCashMovement` (to the safe, change float) stays cash of the company
and is not posted. `get#ZReport` also works on an open shift, as an X report. A closed shift is
fixed. `PosShiftList` shows all shifts to the admin.

## Restaurant

`PosRestaurantServices100`, app `restaurant`. A tab (`PosTab`) is an order that stays open at a table
(an Asset of class `AsClsTable`, placed by `PosTableLayout`). Lines are added one by one through
mantle so an order item keeps its id: the kitchen state in `PosLine` hangs on it, and a back office
save of the order is refused.

- **Lines**: `New`, `Sent`, `Ready`, `Served`, `Voided`. A new line can change or go; once sent it is
  voided: quantity zero, not charged, still visible, counted on the Z report.
- **Modifiers**: `PosModifierGroup` with `minSelect`/`maxSelect`, on products. The price goes into the
  price of the line and the name into its description, `PosLineModifier` keeps what was chosen.
- **Kitchen**: `send#TabToKitchen` makes a ticket of the new lines. After the commit
  `send#KitchenSignal` sends topic `posKitchen` to the users of the tenant, with no content: screens
  fetch again (`PosLiveRefresh`) and also poll every 15 seconds, a signal can get lost.
  `NotificationBloc` keeps the topic out of the bell. The signal reaches the JVM it runs on only.
- **Paying**: `settle#Tab` shares `finish#PosOrder` with the till and needs an open shift.
  `calculate#TabSplit` splits equally or by item; the last share takes what rounding leaves and all
  shares settle at once: one order, one invoice, a payment per share, one receipt.

## Frontend

Block `growerp_pos`: `PosCheckoutScreen` (tiles and cart side by side from 700 wide, stacked below),
`PosTenderDialog`, `PosReceiptDialog`, `buildPosReceipt` for the 80mm PDF. A scanner works as a
keyboard: it types into the search field and presses enter. Barcodes are entered in the product
dialog (`ProductIdentification` of type `PidtEan`).

App `shop` opens on the checkout; the other menu items are for the admin, staff are added under
Staff. An employee (`GROWERP_M_EMPLOYEE`) is the cashier: sells, opens and closes the till. Refunds
and the list of shifts are for the admin. The `GROWERP_POS` domain
is only granted to companies registered in an app with the checkout on its menu.

## Waiter and admin

In `restaurant` an employee is a waiter and works the kitchen display, without a shift: open a
table, enter the order, take off what the kitchen has not seen, send, move or free the table. The
admin takes the money (`settle#Tab`, split bill, needs an open shift), voids what the kitchen has
seen and sets up tables and modifiers. `check#PosAdmin` enforces this in the services: the
`GROWERP_POS` REST domain is open to every employee, so hiding a button is not enough.
