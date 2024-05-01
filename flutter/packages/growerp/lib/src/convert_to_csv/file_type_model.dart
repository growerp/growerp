// The sequence in this list defines the squence of loading the files.

enum FileType {
  company,
  glAccount,
  product,
  category,
  itemType,
  paymentType,
  user,
  asset,
  finDocTransaction,
  finDocTransactionItem,
  finDocInvoicePurchase,
  finDocInvoicePurchaseItem,
  finDocInvoiceSale,
  finDocInvoiceSaleItem,
  finDocPaymentPurchase,
  finDocPaymentPurchaseItem, // single item for amount, glAccount
  finDocPaymentSale,
  finDocPaymentSaleItem, // single item for amount, glAccount
  finDocOrderPurchase,
  finDocOrderPurchaseItem,
  finDocOrderSale,
  finDocOrderSaleItem,
  website,
  unknown
}
