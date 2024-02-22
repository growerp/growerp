/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

// see README.md for documentation

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';
import '../file_type_model.dart';
import '../logger.dart';

var logger = Logger(filter: MyFilter());
List<String> ids = []; //keep id's to avoid duplicates
String outputDirectory = 'growerpOutput';
//SAGA50 account types
// convert accountclass, the field that specifies debit/credit
// Debit and Credit are accepted values.
// this map first value is converted to the second value
// with convertClass[inputvalue] gives: outputValue
/*
10 Accounts Payable
1 Accounts Receivable
6 Accumulated Depreciation
24 Expenses
5 Fixed Assets
21 Income
0 Cash
2 Inventory
23 Cost of Sales
14 Long term liabilities
16 Equity - doesn't close (Corporation)
8 Other assets
19 Equity - gets closed (Proprietorship)
4 Other current assets
18 Equity - Retained Earnings
12 Other current liabilities
*/
// SAGE50 coversion type to class
Map convertClass = {
  '0': 'Cash and Equivalent',
  'Cash': 'Cash and Equivalent',
  '1': 'Accounts Receivable',
  'Accounts Receivable': 'Accounts Receivable',
  '2': 'Inventory Assets',
  'Inventory': 'Inventory Assets',
  '4': 'Other Assets',
  'Other Current Assets': 'Other Assets',
  '5': 'Long Term Assets',
  'Fixed Assets': 'Long Term Assets',
  '6': 'Accumulated Depreciation (contra)',
  'Accumulated Depreciation': 'Accumulated Depreciation (contra)',
  '8': 'Other Assets',
  'Other Assets': 'Other Assets',
  '10': 'Accounts Payable',
  'Accounts Payable': 'Accounts Payable',
  '12': 'Current Liabilities',
  'Other Current Liabilities': 'Current Liabilities',
  '14': 'Long Term Liabilities',
  'Long Term Liabilities': 'Long Term Liabilities',
  '18': 'Retained Earnings',
  'Equity-Retained Earnings': 'Retained Earnings',
  '19': 'Equity Distribution',
  'Equity-gets closed': 'Equity Distribution',
  '21': 'Goods Revenue',
  'Income': 'Goods Revenue',
  '23': 'Cost of Sales',
  'Cost of Sales': 'Cost of Sales',
  '24': 'Other Expenses',
  'Expenses': 'Other Expenses',
  '98': 'Discounts and Write-downs',
  '99': 'Goods Revenue',
  '16': 'Owners Equity',
  '97': 'Customer Returns',
  'Sales Discounts': 'Discounts and Write-downs',
};

// used on order/invoice/return with default accountCode
// in backend entity ItemTypeGlAccount and view ItemTypeAndGlAccount
// which also comtains the companyId/organizationPartyId
String accountCodeToItemType(String accountCode, String pseudoProductId) {
  Map accountCodes = {
    '12000': 'ItemProduct',
    '15200': 'ItemProduct', // inv
    '15400': 'ItemProduct', // inv
    '23100': 'ItemSalesTax', // inv
    '24500': 'ItemSalesTax', // inv
    '39005': 'ItemSales', // inv
    '45500': 'ItemSales', // inv
    '50000': 'ItemProduct',
    '50005': 'ItemProduct',
    '50008': 'ItemProduct', //inv
    '50030': 'ItemProduct',
    '50040': 'ItemProduct',
    '57500': 'ItemShipping',
    '75500': 'ItemProduct',
  };

  if (accountCodes[accountCode] == 'ItemProduct' && pseudoProductId == '')
    return ('ItemSales');
  return (accountCodes[accountCode] ?? 'ItemExpense');
}

/// specify filenames here, * allowed for names with the same starting characters
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
      //searchFiles.add('Trial_Balance_2020-06-07.csv');
      searchFiles.add('Trial_Balance_2020-06-07-noposted.csv');
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
    case FileType.finDocTransaction:
    case FileType.finDocTransactionItem:
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

// specify file wide changes here
String convertFile(FileType fileType, String string, String fileName) {
  /// file type dependent changes here
  switch (fileType) {
    case FileType.glAccount:
      string = string
          .replaceFirst(
              '10205,"Checking Acct, Mission Bank",Cash,,\n',
              '10205,"Checking Acct, Mission Bank",Cash,,\n'
                  '10206,Deleted bank account,Cash,,\n')
          .replaceFirst(
              "27500,Loan - Kern Schools C. U.,Long Term Liabilities,,\n",
              "27500,Loan - Kern Schools C. U.,Long Term Liabilities,,\n"
                  "27600,Loan - Old,Long Term Liabilities,,\n")
          .replaceFirst(
              "10100,Cash on Hand,", "10000,Assets,Cash,,\n10100,Cash on Hand,")
          .replaceFirst(
              "39005,Capital,", "30000,Equity,Equity-Retained Earnings,,\n39005,Capital,")
          .replaceFirst("85000,Discount for Early Payment,",
              "80000,Discounts,Cash,,\n85000,Discount for Early Payment,")
          .replaceFirst(
              '24500,Calf. State Income Tax Payable,Other Current Liabilities,',
              '24500,Calf. State Income Tax Payable,Current Liability (contra),')
          .replaceFirst(
              '24700,Federal Income Tax Payable,Other Current Liabilities,',
              '24700,Federal Income Tax Payable,Current Liability (contra),')
          .replaceFirst('48000,Sales Returns and Allowances,Income,',
              '48000,Sales Returns and Allowances,Customer Returns (contra),')
          .replaceFirst('49000,Sales Discounts,Income,',
              '49000,Sales Discounts,Discounts and Write-downs (contra),')
          .replaceFirst('50050,Raw Materials,Cost of Sales,',
              '50050,Raw Materials,Good and Material Cost (contra),')
          .replaceFirst('61500,Bad Debt,Expenses,',
              '61500,Bad Debt,Allowance For Bad Debts (contra),')
          .replaceFirst('89500,Discount for Early Payment,Cost of Sales,',
              '89500,Discount for Early Payment,Expenses (contra),');
      break;
    default:
  }

  /// filename dependent changes here
  switch (fileName) {
    default:
  }
  return string;
}

/// specify columns to columns mapping for every row here
List<String> convertRow(FileType fileType, List<String> columnsFrom,
    String fileName, List<List<String>> images) {
  List<String> columnsTo = [];

  String getImageFileName(FileType fileType, String id) {
    if (images[0].isEmpty) return '';
    for (List row in images) {
      if (row[0] == fileType.name && row[1] == id) {
        // if not file path, add it using the filename
        if (row[2][0] != '/')
          return '${fileName.substring(0, fileName.lastIndexOf('/') + 1)}${row[2]}';
        return row[2];
      }
    }
    return '';
  }

  String dateConvert(String date) {
    var dateList = date.split('/');
    var prefix;
    if (dateList[2] == '99')
      prefix = '19';
    else
      prefix = '20';
    return "${prefix}${dateList[2]}-${dateList[0].padLeft(2, '0')}-${dateList[1].padLeft(2, '0')}";
  }

  switch (fileType) {
    /// convert to [itemTypeCsvFormat]
    case FileType.itemType:
      if (columnsFrom[0] == '') return [];
      columnsTo.add(columnsFrom[0]);
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      return columnsTo;

    case FileType.paymentType:
      // 0: type, 1: descr, 2:account code, 3 account name,
      // 4: is payable, 5: is applied
      if (columnsFrom[0] == '') return [];
      columnsTo.add(columnsFrom[0]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[4]);
      columnsTo.add(columnsFrom[5]);
      return columnsTo;

    /// convert to [glAccountCsvFormat]
    case FileType.glAccount:
      // remove empty and double id's
      if (columnsFrom[0] == '' || ids.contains(columnsFrom[0])) return [];
      ids.add(columnsFrom[0]);
      columnsTo.add(columnsFrom[0]); //0 accountCode
      columnsTo.add(columnsFrom[1]); //1 account name
      columnsTo.add(convertClass[columnsFrom[2]] != null
          ? convertClass[columnsFrom[2]]
          : columnsFrom[2]); //2 class
      columnsTo.add(''); //3 type empty
      if (columnsFrom.length > 2 && columnsFrom[3] != '') {
        columnsTo.add(columnsFrom[3].replaceAll(',', ''));
      } else {
        if (columnsFrom.length > 3 && columnsFrom[4] != '') {
          columnsTo.add("-${columnsFrom[4].replaceAll(',', '')}");
        }
      }
      return columnsTo;

    /// convert to [productCsvFormat]
    case FileType.product:
      // 17: productId 18: description
      if (columnsFrom[17] != '' && !ids.contains(columnsFrom[17])) {
        ids.add(columnsFrom[17]);
        columnsTo.add(columnsFrom[17]); // id
        columnsTo.add('Physical Good'); // type
        columnsTo.add(columnsFrom[18]); // name
        columnsTo.add(''); // description
        columnsTo.add(''); // list price
        columnsTo.add(''); // sales price
        columnsTo.add(''); // cost price
        columnsTo.add('true'); // use warehouse
        if (columnsFrom[12] != '') {
          columnsTo.add('sales product');
        } // category
        if (columnsFrom[14] != '') {
          columnsTo.add('purchase product'); // category
        }
        columnsTo.add(''); // category 1
        columnsTo.add(''); // category 2
        columnsTo.add(''); // category 3
        columnsTo.add(getImageFileName(fileType, columnsFrom[17])); //image
      }
      return columnsTo;

    /// convert to [companyCsvFormat]
    case FileType.company:
      if (fileName.contains('customer') || fileName.contains('main-company')) {
        // 0:partyId,partyType,Customer ID,Customer Name,Inactive,
        // 5:Bill to Address-Line One,Bill to Address-Line Two,Bill to City,
        // 8:Bill to State,Bill to Zip,Bill to Country,Bill to Sales Tax ID,
        // 12:Telephone 1,Telephone 2,Fax Number,Customer E-mail,
        // 16:Resale Number,Discount Days,Discount Percent,Customer Web Site
        columnsTo.add(columnsFrom[2]); // id
        if (fileName.contains('main-company'))
          columnsTo.add(Role.company.value);
        else
          columnsTo.add(Role.customer.value); //role
        columnsTo.add(columnsFrom[3]); //name
        columnsTo.add(columnsFrom[15]); //email
        columnsTo.add(columnsFrom[12]); // teleph
        columnsTo.add('USD'); //curr
        columnsTo.add(getImageFileName(fileType, columnsFrom[2])); //image
        columnsTo.add(columnsFrom[5]); //address1
        columnsTo.add(columnsFrom[6]); //address2
        columnsTo.add(columnsFrom[9]); //postal
        columnsTo.add(columnsFrom[7]); //city
        columnsTo.add(columnsFrom[8]); //state,prov
        columnsTo.add('United States'); //country
      }

      if (fileName.contains('vendor')) {
        // 0:partyId,partyType,Vendor ID,Vendor Name,Inactive,Contact,
        // 6:Address-Line One,Address-Line Two,City,State,Zip,Country,
        // 12:Remit to 1 Name,Remit to 1 Address Line 1,
        // 14:Remit to 1 Address Line 2,Remit to 1 City,Remit to 1 State,
        // 17:Remit to 1 Zip,Remit to 1 Country,Telephone 1,Telephone 2,
        // 21:Fax Number,Vendor E-mail,Vendor Web Site,Account Number,
        // 25:Due Days,Discount Days,Discount Percent
        columnsTo.add(columnsFrom[2]); //id
        columnsTo.add(Role.supplier.value); // role
        columnsTo.add(columnsFrom[3]); //name
        columnsTo.add(columnsFrom[22]); //email
        columnsTo.add(columnsFrom[19]); // teleph
        columnsTo.add('USD'); //curr
        columnsTo.add(''); //image
        columnsTo.add(columnsFrom[6]); //address1
        columnsTo.add(columnsFrom[7]); //address2
        columnsTo.add(columnsFrom[10]); //postal
        columnsTo.add(columnsFrom[8]); //city
        columnsTo.add(columnsFrom[9]); //state,prov
        columnsTo.add(columnsFrom[10]); //country
      }

      // from ledger spreadsheet
      if (fileName.startsWith('0b')) {
        if (columnsFrom[11].isEmpty && columnsFrom[13].isEmpty) return [];
        columnsTo.add('');
        if (columnsFrom[11].isNotEmpty) {
          if (ids.contains(columnsFrom[11])) return [];
          ids.add(columnsFrom[11]);
          columnsTo.add(columnsFrom[11]);
          columnsTo.add(Role.customer.value);
          columnsTo.add(columnsFrom[12]);
        }
        if (columnsFrom[13].isNotEmpty) {
          if (ids.contains(columnsFrom[13])) return [];
          ids.add(columnsFrom[13]);
          columnsTo.add(columnsFrom[13]);
          columnsTo.add(Role.supplier.value);
          columnsTo.add(columnsFrom[14]);
        }
        if (columnsTo[1] == 'customerId') {
          return [];
        }
      }
      return columnsTo;

    case FileType.user:
      // 15: employeeId 16: employee name
      if (columnsFrom[15].isEmpty || columnsFrom[16].isEmpty) return [];

      // split up name in first/last
      var lastBlank = columnsFrom[16].lastIndexOf(' ');

      columnsTo.add(columnsFrom[15]);
      if (lastBlank == -1) {
        columnsTo.add('');
        columnsTo.add(columnsFrom[16]);
      } else {
        columnsTo.add(columnsFrom[16].substring(0, lastBlank));
        columnsTo.add(columnsFrom[16].substring(lastBlank + 1));
      }
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('Employee');
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('OrgInternal');
      return columnsTo;

    case FileType.finDocOrderPurchase:
      // 1:vendorId 2:vendorName, 9:order id, 10:date(mm/dd/yy),
      // 11:closed(TRUE/FALSE) 27: item number, 28: quantity, 29: productId,
      // 30: descr, 31: accountCode, 32: price, 33: amount

      columnsTo.add(
          "${dateConvert(columnsFrom[10])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('false');
      columnsTo.add('Order');
      columnsTo.add('');
      columnsTo.add(dateConvert(columnsFrom[10]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[9]);
      return columnsTo;

    case FileType.finDocOrderPurchaseItem:
      // 1:vendorId 2:vendorName, 9:order id, 10:date(mm/dd/yy),
      // 11:closed(TRUE/FALSE) 27: seq number, 28: quantity, 29: productId,
      // 30: descr, 31: accountCode, 32: price, 33: amount

      columnsTo.add(
          "${dateConvert(columnsFrom[10])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Order');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[29]); // product id
      columnsTo.add(columnsFrom[30]); // descr
      columnsTo.add(columnsFrom[28]); // quant
      columnsTo.add(columnsFrom[32]); // price
      columnsTo.add(columnsFrom[31]); // itemType accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[31], columnsFrom[29]));
      return columnsTo;

    case FileType.finDocInvoicePurchase:
      // 1:vendorId 2:vendorName, 3:reference id, 4:creditMemo 5:date(mm/dd/yy),
      // 16:discountAmount, 22: orderId,
      // 7: item number, 24: quantity, 25: productId,
      // 26: descr, 27: accountCode, 28: price, 29: amount, 30: terms

      // just use to combine items, need to replace by seq num
      columnsTo.add(
          "${dateConvert(columnsFrom[5])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('false');
      columnsTo.add('Invoice');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[5]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]); // put refnum here
      return columnsTo;

    case FileType.finDocInvoicePurchaseItem:
      // 1:vendorId 2:vendorName, 3:reference, 4:creditMemo 5:date(mm/dd/yy),
      // 16:discountAmount, 22: orderId,
      // 7: item number, 24: quantity, 25: productId,
      // 26: descr, 27: accountCode, 28: price, 29: amount, 30: terms

      columnsTo.add(
          "${dateConvert(columnsFrom[5])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Invoice');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[25]); // product id
      columnsTo.add(columnsFrom[26]); // descr
      columnsTo.add(columnsFrom[24]); // quant
      columnsTo.add(columnsFrom[28]); // price
      columnsTo.add(columnsFrom[27]); // itemType accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[27], columnsFrom[25]));
      return columnsTo;

    case FileType.finDocPaymentPurchase:
      // 0: partyId, 1:vendorId 2:vendorName, 3:checkname, 10: checkNumber, 11:date(mm/dd/yy),
      // 12: memo // contains reference to invoice/order,  13: cash accountCode,
      // 14: total amount, 18: date cleared, 20: acct Transaction invoiceId, 21: discount Amount
      columnsTo.add(
          "${dateConvert(columnsFrom[11])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('false');
      columnsTo.add('Payment');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[11]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[20] != ''
          ? columnsFrom[20]
          : columnsFrom[12]); // trans invoice id in reference
      columnsTo.add(columnsFrom[10]);
      String amount = columnsFrom[14].replaceAll('-', ''); // check number
      columnsTo.add(amount); // total amount
      if (amount == '0' || amount == '' || double.tryParse(amount) == null)
        return []; // ignore records with zero/invalid amounts
      return columnsTo;

    case FileType.finDocPaymentPurchaseItem: // just a single record for amount
      // 1:vendorId 2:vendorName, 3:checkname, 10: checkNumber, 11:date(mm/dd/yy),
      // 13: cash accountCode, 18: date cleared, 20: invoiceId, 21: discount Amount,
      // 24: productId, 23: quantity, 25: description 26: accountCode, 28: price
      columnsTo.add(
          "${dateConvert(columnsFrom[11])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Payment');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[24]); // product id
      columnsTo.add(columnsFrom[25]); // descr
      columnsTo.add(columnsFrom[23]); // quant
      columnsTo.add(columnsFrom[28]); // price
      columnsTo.add(columnsFrom[26]); // accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[27], columnsFrom[25]));
      return columnsTo;

    case FileType.finDocOrderSale:
      // 1:custId 2:custName, 3:order id, 4:date(mm/dd/yy),
      // 6:closed(TRUE/FALSE) 21: item number, 22: quantity, 23: productId,
      // 24: descr, 25: accountCode, 26: price, 28: amount

      columnsTo.add(
          "${dateConvert(columnsFrom[4])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('true');
      columnsTo.add('Order');
      columnsTo.add('');
      columnsTo.add(dateConvert(columnsFrom[4]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]);
      return columnsTo;

    case FileType.finDocOrderSaleItem:
      // 1:custId 2:custName, 3:order id, 4:date(mm/dd/yy),
      // 6:closed(TRUE/FALSE) 21: item number, 22: quantity, 23: productId,
      // 24: descr, 25: accountCode, 26: price, 28: amount

      columnsTo.add(
          "${dateConvert(columnsFrom[4])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Order');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[23]); // product id
      columnsTo.add(columnsFrom[24]); // descr
      columnsTo.add(columnsFrom[22]); // quant
      columnsTo.add(columnsFrom[26]); // price
      columnsTo.add(columnsFrom[25]); // itemType accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[25], columnsFrom[23]));
      return columnsTo;

    case FileType.finDocInvoiceSale:
      // 1:custId 2:custName, 3:reference id, 4: applyInvoiceId 5:creditMemo 6:date(mm/dd/yy),
      // 15: custPO 16:discountAmount, 17: ship date,
      // 28: quantity, 30: productId,
      // 32: descr, 33: accountCode, 34: price, 36: amount, 30: terms

      // just use to combine items, need to replace by seq num
      columnsTo.add(
          "${dateConvert(columnsFrom[6])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('true');
      columnsTo.add('Invoice');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[6]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]); // put refnum here
      return columnsTo;

    case FileType.finDocInvoiceSaleItem:
      // 1:custId 2:custName, 3:reference id, 4: applyInvoiceId 5:creditMemo 6:date(mm/dd/yy),
      // 15: custPO 16:discountAmount, 17: ship date,
      // 28: quantity, 30: productId,
      // 32: descr, 33: accountCode, 34: price, 36: amount, 30: terms

      columnsTo.add(
          "${dateConvert(columnsFrom[6])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Invoice');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[30]); // product id
      columnsTo.add(columnsFrom[32]); // descr
      columnsTo.add(columnsFrom[28]); // quant
      columnsTo.add(columnsFrom[34]); // price
      columnsTo.add(columnsFrom[33]); // itemType accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[33], columnsFrom[30]));
      return columnsTo;

    case FileType.finDocPaymentSale:
      // 0: partyId, 1:custId 2:custName, 3:dep date, 4:reference 5: date,
      // 8: amount, 11: paid on invoices,  14: invoiceId paid
      // 16: discount amount, 7: glaccount, 11: discount account 18: rec account
      // 21: amount

      columnsTo.add(
          "${dateConvert(columnsFrom[5])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('true');
      columnsTo.add('Payment');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[5]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[4]); // trans invoice id in reference
      columnsTo.add('');
      String amount = columnsFrom[21].replaceAll('-', ''); // check number
      columnsTo.add(amount); // total amount
      return columnsTo;

    case FileType.finDocPaymentSaleItem: // just a single record for amount
      // 0: partyId, 1:custId 2:custName, 3:dep date, 4:reference 6: pay method,
      // 8: amount, 11: paid on invoices,  14: invoiceId paid
      // 16: discount amount, 7: glaccount, 11: discount account 18: rec account
      // 21: amount
      columnsTo.add(
          "${dateConvert(columnsFrom[5])}-${columnsFrom[0]}"); // will be replaced by sequential id
      columnsTo.add('Payment');
      columnsTo.add(''); //seqId by system
      columnsTo.add(''); // product id
      columnsTo.add(''); // descr
      columnsTo.add(''); // quant
      columnsTo.add(''); // price
      columnsTo.add(columnsFrom[18]); // accountCode
      return columnsTo;

    case FileType.finDocTransaction:
      // 0: accountId, 2:date, 3:reference, 4:journalId, 5:description,
      // 11: customerId, 13: vendorId, 15: employeeId,
      String otherCompanyId = '', otherCompanyName = '', otherUserId = '';
      bool sales = false;
      if (columnsFrom[11].isNotEmpty) {
        otherCompanyId = columnsFrom[11];
        otherCompanyName = columnsFrom[12];
        sales = true;
      }
      if (columnsFrom[13].isNotEmpty) {
        otherCompanyId = columnsFrom[13];
        otherCompanyName = columnsFrom[14];
        sales = false;
      }

      if (columnsFrom[15].isNotEmpty) {
        otherUserId = columnsFrom[15];
        otherCompanyId = 'Main Company';
        otherCompanyName = columnsFrom[16];
        sales = false;
      }
      columnsTo.add(
          "${dateConvert(columnsFrom[2])}-${columnsFrom[3]}"); // will be replaced by sequential id
      columnsTo.add(sales.toString());
      columnsTo.add('Transaction');
      columnsTo.add(columnsFrom[5]);
      columnsTo.add(dateConvert(columnsFrom[2]));
      columnsTo.add(otherUserId);
      columnsTo.add(otherCompanyId);
      columnsTo.add(otherCompanyName);
      columnsTo.add(columnsFrom[3]); // reference
      return columnsTo;

    case FileType.finDocTransactionItem:
      // 0: accountId, 2:date, 3:reference, 5: debit amount, 6 credit amount,
      // 17: productId, 18: line description,
      bool isDebit = true;
      var amount = columnsFrom[6];
      if (columnsFrom[7].isNotEmpty) {
        isDebit = false;
        amount = columnsFrom[7];
      }

      columnsTo.add(
          "${dateConvert(columnsFrom[2])}-${columnsFrom[3]}"); // will be replaced by sequential id
      columnsTo.add('Transaction');
      columnsTo.add('');
      columnsTo.add(columnsFrom[17]);
      columnsTo.add(columnsFrom[18]);
      columnsTo.add('');
      columnsTo.add(amount);
      columnsTo.add(columnsFrom[0]);
      columnsTo.add(isDebit.toString());
      return columnsTo;
    //
    // do some more conversion here, depending on filetype.
    //
    default: // no output
      return [];
  }
}

Future<void> main(List<String> args) async {
  var logger = Logger(filter: MyFilter());
  if (args.isEmpty) {
    logger.e(
        "Specify a directory and optionally a filetype like: ${FileType.values}?");
    exit(1);
  }

  logger.i(
      "Input directory: ${args[0]} fileType: ${args.length > 1 ? args[1] : ''}");

  if (args.length == 2 && !FileType.values.toString().contains(args[1])) {
    logger.e("FileType: ${args[1]} not recognized");
    exit(1);
  }

  if (isDirectory(outputDirectory) && args.length == 1) {
    logger.e(
        "output directory $outputDirectory already exists, cannot overwrite");
    exit(1);
  }

  // create output directory
  if (!isDirectory(outputDirectory)) createDir(outputDirectory);
  // copy images if present
  List<List<String>> images = [[]];
  if (isDirectory('${args[0]}/images')) {
    if (!isDirectory('$outputDirectory/images'))
      createDir('$outputDirectory/images');
    copyTree('${args[0]}/images', '$outputDirectory/images', overwrite: true);
    copy('${args[0]}/images.csv', '$outputDirectory/images.csv',
        overwrite: true);
    // get images file
    String imagesCsv = File('${args[0]}/images.csv').readAsStringSync();
    images = fast_csv.parse(imagesCsv);
  }
  for (var fileType in FileType.values) {
    if (fileType == FileType.unknown) continue;
    if (args.length == 2 && fileType.name != args[1]) continue;
    // define search file names for every filetype
    List<String> searchFiles = getFileNames(fileType);
    if (searchFiles.isEmpty) continue;
    // list of files to process
    List<String> files = [];
    for (String searchFile in searchFiles) {
      files.addAll(find(searchFile, workingDirectory: args[0]).toList());
    }
    if (files.isEmpty) {
      logger.e(
          "No ${searchFiles.join()} csv files found in directory ${args[0]}, skipping");
    }
    // process files and convert rows
    List<List<String>> convertedRows = [];
    for (String fileInput in files) {
      logger.i("Processing filetype: ${fileType.name} file: ${fileInput}");
      // parse raw csv file string
      String contentString = File(fileInput).readAsStringSync();
      // general changes in content
      contentString = convertFile(fileType, contentString, fileInput);

      // parse input file
      List<List<String>> inputCsvFile = fast_csv.parse(contentString);
      // convert rows
      int index = 0;
      for (final row in inputCsvFile) {
        if (++index % 10000 == 0) print("processing row: $index");
        if (row == inputCsvFile.first) continue; // header line
        List<String> convertedRow =
            convertRow(fileType, row, fileInput, images);
        // print("==old: $row new: $convertedRow");
        if (convertedRow.isNotEmpty) convertedRows.add(convertedRow);
      }
      logger.i(
          "filetype: ${fileType.name} file: ${fileInput} $index records processed");
    }
    // print("==2==${convertedRows.length} 0:${convertedRows[0]}");

    // prepare output files and run post processing like mandatory sort
    int csvLength = 0;
    String csvFormat = '';
    switch (fileType) {
      case FileType.itemType:
        csvFormat = itemTypeCsvFormat;
        csvLength = itemTypeCsvLength;
        break;
      case FileType.paymentType:
        csvFormat = paymentTypeCsvFormat;
        csvLength = paymentTypeCsvLength;
        break;
      case FileType.glAccount:
        csvFormat = glAccountCsvFormat;
        csvLength = glAccountCsvLength;
        break;
      case FileType.category:
        csvFormat = categoryCsvFormat;
        csvLength = categoryCsvLength;
        break;
      case FileType.product:
        csvFormat = productCsvFormat;
        csvLength = productCsvLength;
        break;
      case FileType.company:
        csvFormat = companyCsvFormat;
        csvLength = companyCsvLength;
        break;
      case FileType.user:
        csvFormat = userCsvFormat;
        csvLength = userCsvLength;
        // remove doubles
        convertedRows
            .sort((a, b) => (a.asMap()[0] ?? '').compareTo(b.asMap()[0] ?? ''));
        List<List<String>> users = [];
        var lastUser = [];
        for (final convertedRow in convertedRows) {
          if (lastUser.isEmpty || convertedRow[0] != lastUser[0]) {
            users.add(convertedRow);
          }
          lastUser = convertedRow;
        }
        convertedRows = users;
        break;
      case FileType.finDocTransaction:
      case FileType.finDocOrderPurchase:
      case FileType.finDocInvoicePurchase:
      case FileType.finDocPaymentPurchase:
      case FileType.finDocOrderSale:
      case FileType.finDocInvoiceSale:
      case FileType.finDocPaymentSale:
        csvFormat = finDocCsvFormat;
        csvLength = finDocCsvLength;
        convertedRows
            .sort((a, b) => (a.asMap()[0] ?? '').compareTo(b.asMap()[0] ?? ''));
        // remove detail lines & create sequence Id
        List<String> lastRow = [];
        List<List<String>> headerRows = [];
        int seqNumber = 10000;
        for (final row in convertedRows) {
//          print(
//              "==process cur: ${row[0]} seq: $seqNumber ${lastRow.isEmpty ? 'empty' : lastRow[0]}");
          if (row[0].isEmpty) continue;
          if (lastRow.isEmpty || row[0] != lastRow[0]) {
//            print(" create header");
            List<String> newRow = List.from(row);
            // replace by sequential number
            newRow[0] = (seqNumber++).toString();
            headerRows.add(newRow);
          }
          lastRow = row;
        }
        convertedRows = headerRows;
        break;
      case FileType.finDocTransactionItem:
      case FileType.finDocOrderPurchaseItem:
      case FileType.finDocInvoicePurchaseItem:
      case FileType.finDocPaymentPurchaseItem:
      case FileType.finDocOrderSaleItem:
      case FileType.finDocInvoiceSaleItem:
      case FileType.finDocPaymentSaleItem:
        csvFormat = finDocItemCsvFormat;
        csvLength = finDocItemCsvLength;
        convertedRows
            .sort((a, b) => (a.asMap()[0] ?? '').compareTo(b.asMap()[0] ?? ''));
        // replace id by sequential number
        List<List<String>> headerRows = [];
        List<String> lastRow = [];
        int seqNumber = 10000;
        for (final row in convertedRows) {
          if (lastRow.isNotEmpty && row[0] != lastRow[0]) {
            seqNumber++;
          }
          List<String> newRow = List.from(row);
          newRow[0] = seqNumber.toString();
          headerRows.add(newRow);
          lastRow = row;
        }
        convertedRows = headerRows;
        // sort better use maps for empty values
        // sort by just reference number
        break;
      default:
    }

    List<String> fileContent = [];
    int fileIndex = 0;
    for (int record = 0; record < convertedRows.length; record++) {
      if (record % 2000 == 0 && record != 0) {
        // wait for id change
        while (convertedRows[record][0] == convertedRows[record - 1][0]) {
          fileContent.add(createCsvRow(convertedRows[record++], csvLength));
        }
        // insert header
        fileContent.insert(0, csvFormat);
        // create file
        final file = File(
            "$outputDirectory/${fileType.name}-${(++fileIndex).toString().padLeft(3, '0')}.csv");
        file.writeAsStringSync(fileContent.join());
        logger.i(
            "Output file created: ${fileType.name}-${(fileIndex).toString().padLeft(3, '0')}.csv ${fileContent.length} records");
        // start new file
        fileContent = [];
      }
      fileContent.add(createCsvRow(convertedRows[record], csvLength));
    }
    if (fileContent.isNotEmpty) {
      fileContent.insert(0, csvFormat);
      final file = File(
          "$outputDirectory/${fileType.name}-${(++fileIndex).toString().padLeft(3, '0')}.csv");
      file.writeAsStringSync(fileContent.join());
      logger.i(
          "Output file created: ${fileType.name}-${(fileIndex).toString().padLeft(3, '0')}.csv ${fileContent.length} records");
    }
  }
  exit(0);
}
