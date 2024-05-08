import 'package:logger/logger.dart';
import 'file_type_model.dart';
import '../logger.dart';

var logger = Logger(filter: MyFilter());

/// specify filenames here, * allowed for names with the same starting characters
///

List<String> getFileNames(FileType fileType) {
  List<String> searchFiles = [];
  switch (fileType) {
    case FileType.itemType:
      searchFiles.add('itemType.csv');
      break;
    case FileType.paymentType:
      searchFiles.add('paymentType.csv');
      break;
    case FileType.company:
      searchFiles.add('1-3-customer_list.csv');
      searchFiles.add('2-3-vendor_list.csv');
      searchFiles.add('main-company.csv');
      break;

    case FileType.glAccount:
      searchFiles.add('4-1-chart_of_accounts_list.csv'); // basic layout
      break;

    case FileType.product:
    case FileType.user:
    case FileType.finDocTransaction:
    case FileType.finDocTransactionItem:
      searchFiles.add('general_ledger_2022Q3.ods'); // posted start
      break;
    case FileType.finDocInvoicePurchase:
    case FileType.finDocInvoicePurchaseItem:
      searchFiles.add('2b1-purchases_journal.csv');
      break;
    case FileType.finDocInvoiceSale:
    case FileType.finDocInvoiceSaleItem:
      searchFiles.add('3b1-sales_journal.csv');
      break;
    case FileType.finDocPaymentPurchase:
      searchFiles.add('2c1-payments_journal.csv');
      break;
    case FileType.finDocPaymentSale:
      searchFiles.add('3c1-receipts_journal.csv');
      break;
    case FileType.finDocOrderPurchase:
    case FileType.finDocOrderPurchaseItem:
      searchFiles.add('2a1-purchase_order_journal.csv');
      break;
    case FileType.finDocOrderSale:
    case FileType.finDocOrderSaleItem:
      searchFiles.add('3a1-sales_order_journal.csv');
      break;
    case FileType.finDocPaymentSaleItem:
    case FileType.finDocPaymentPurchaseItem:
    case FileType.category:
    case FileType.asset:
    case FileType.website:
      break;
    default:
      logger.w("No files found for fileType: ${fileType.name}");
  }
  return searchFiles;
}
