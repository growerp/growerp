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
    case FileType.glAccount:
      //searchFiles.add('4-1-chart_of_accounts_list.csv');
      searchFiles.add('Trial_Balance_2019-12-31.csv');
      //searchFiles.add('Trial_Balance_2020-06-07.csv');
      //searchFiles.add('Trial_Balance_2020-06-07-noposted.csv');
      break;
    case FileType.company:
      searchFiles.add('1-3-customer_list.csv');
      searchFiles.add('2-3-vendor_list.csv');
      searchFiles.add('main-company.csv');
      break;
    case FileType.finDocOrderPurchase:
    case FileType.finDocOrderPurchaseItem:
      searchFiles.add('2a-purchase_order_journal.csv');
      searchFiles.add('2a1-purchase_order_journal.csv');
      break;
    case FileType.finDocInvoicePurchase:
    case FileType.finDocInvoicePurchaseItem:
      searchFiles.add('2b-purchases_journal.csv');
      searchFiles.add('2b1-purchases_journal.csv');
      break;
    case FileType.finDocPaymentPurchase:
    case FileType.finDocPaymentPurchaseItem:
      searchFiles.add('2c-payments_journal.csv');
      searchFiles.add('2c1-payments_journal.csv');
      break;
    case FileType.finDocOrderSale:
    case FileType.finDocOrderSaleItem:
      searchFiles.add('3a-sales_order_journal.csv');
      searchFiles.add('3a1-sales_order_journal.csv');
      break;
    case FileType.finDocInvoiceSale:
    case FileType.finDocInvoiceSaleItem:
      searchFiles.add('3b-sales_journal.csv');
      searchFiles.add('3b1-sales_journal.csv');
      break;
    case FileType.finDocPaymentSale:
    case FileType.finDocPaymentSaleItem:
      searchFiles.add('3c-receipts_journal.csv');
      searchFiles.add('3c1-receipts_journal.csv');
      break;
    case FileType.product:
    case FileType.user:
      searchFiles.add('0b*.csv');
      break;
    case FileType.finDocTransaction:
    case FileType.finDocTransactionItem:
      searchFiles
          .add('Trial_Balance_2019-12-31.csv'); // generate starting balance
      searchFiles.add('0b*.csv');
      // searchFiles.add('0b-yearAll1Test*.csv');
      break;
    case FileType.category:
    case FileType.asset:
    case FileType.website:
      break;
    default:
      logger.w("No files found for fileType: ${fileType.name}");
  }
  return searchFiles;
}
