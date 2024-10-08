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
  finDocOrderPurchase,
  finDocOrderPurchaseItem,
  finDocOrderSale,
  finDocOrderSaleItem,
  finDocInvoicePurchase,
  finDocInvoicePurchaseItem,
  finDocInvoiceSale,
  finDocInvoiceSaleItem,
  finDocPaymentPurchase,
  finDocPaymentPurchaseItem, // single item for amount, glAccount
  finDocPaymentSale,
  finDocPaymentSaleItem, // single item for amount, glAccount
  finDocShipmentIncoming,
  finDocShipmentIncomingItem,
  finDocShipmentOutgoing,
  finDocShipmentOutgoingItem,
  website,
  unknown
}
