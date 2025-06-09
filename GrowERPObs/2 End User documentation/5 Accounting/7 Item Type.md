Item type is used on the order and invoice to indicate the kind of processing and the default account code used on the generated invoice for posting.

The default list:

| itemTypeId         | default account Code   | direction(in/out/either) |     |
| ------------------ | ---------------------- | ------------------------ | --- |
| ItemExpense        | operating expense      | either                   |     |
| ItemProduct        | unreceived inventory   | in                       |     |
| ItemProduct        | product sales          | out                      |     |
| ItemRental         | asset rental sales     | out                      |     |
| ItemSales          | sales revenue          | out                      |     |
| ItemSales          | cost of sales          | in                       |     |
| ItemSalesTax       | sales tax collected    | out                      |     |
| ItemSalesTax       | sales and use taxes    | in                       |     |
| ItemServiceProduct | service sales          | out                      |     |
| ItemShipping       | cost of sales freight  | in                       |     |
| ItemShipping       | shipping fees received | out                      |     |
| ItemVatTax         | VAT collected          | in                       |     |
| ItemVatTax         | VAT used               | out                      |     |


