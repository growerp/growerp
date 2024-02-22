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
  finDocOrderPurchase,
  finDocOrderPurchaseItem,
  finDocInvoicePurchase,
  finDocInvoicePurchaseItem,
  finDocPaymentPurchase,
  finDocPaymentPurchaseItem, // single item for amount, glAccount
  finDocOrderSale,
  finDocOrderSaleItem,
  finDocInvoiceSale,
  finDocInvoiceSaleItem,
  finDocPaymentSale,
  finDocPaymentSaleItem, // single item for amount, glAccount
  website,
  unknown
}
