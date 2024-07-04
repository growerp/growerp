import 'package:growerp_models/growerp_models.dart';

import 'file_type_model.dart';

/// specify columns to columns mapping for every row here
List<String> convertRow(FileType fileType, List<String> columnsFrom,
    String fileName, List<List<String>> images, DateTime? startDate) {
  List<String> columnsTo = [];
  List<String> ids = []; //keep id's to avoid duplicates

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
    if (date.isEmpty) return '';
    if (date.contains('/')) {
      // csv file
      var dateList = date.split('/');
      var prefix;
      if (dateList[2] == '99')
        prefix = '19';
      else
        prefix = '20';
      return "${prefix}${dateList[2]}-${dateList[0].padLeft(2, '0')}-${dateList[1].padLeft(2, '0')}";
    }
    // spreadsheet file
    return date.substring(0, 10);
  }

  // ignore if no begining amount
  if (columnsFrom.length > 4 &&
      columnsFrom[0] == '10100' &&
      columnsFrom[5] == 'Beginning Balance') {
    // create initial transaction for ledger
    columnsFrom[5] = '';
  }
  if (columnsFrom.length > 8 && fileType != FileType.finDocTransactionItem) {
    if (columnsFrom[5] == 'Beginning Balance' ||
        columnsFrom[5] == 'Ending Balance' ||
        columnsFrom[3].isEmpty) return [];
  }

  // reject balances
  if (columnsFrom.length > 8) {
    if (columnsFrom[5] == 'Beginning Balance' && columnsFrom[8] == '')
      return [];
    if (columnsFrom.length > 8 && columnsFrom[5] == 'Ending Balance') return [];
  }
  if (columnsFrom.length > 5 && columnsFrom[5] == 'Change') return [];

  // reject when reference is blank

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
    // 1: account code, 2: account description, 3:account type
    // balances in column 4,5 not used here, but can be provided
    // transaction and transactionitem

    case FileType.glAccount:
      if (fileName.contains('4-1-chart')) {
        // general layout
        columnsTo.add(columnsFrom[0]); //0 accountCode
        columnsTo.add(columnsFrom[1]); //1 account name
        columnsTo.add(convertClass[columnsFrom[2]]); //class
        return columnsTo;
      }
      return [];

    /// convert to [productCsvFormat]
    case FileType.product:
      // 17: productId 18: description
      //  print(columnsFrom.join(','));
      if (columnsFrom.length > 17 &&
          columnsFrom[17] != '' &&
          !ids.contains(columnsFrom[17])) {
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

    /// convert to [assetCsvFormat]
    /// 'AssetClassId, Asset Name, AquiredCost, QOH, ATP, ReceivedDate, '
    /// 'EndOfLifeDate, ProductId, LocationId,';
    case FileType.asset:
      columnsTo.add(''); // type
      columnsTo.add(columnsFrom[4]); // name
      columnsTo.add(columnsFrom[7]); // cost
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add('');
      columnsTo.add(columnsFrom[0]); // product id
      columnsTo.add('');
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
      if (fileName.endsWith('.ods')) {
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
      if (columnsFrom.length < 17) return [];
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
      if (columnsFrom.length < 11) return [];

      columnsTo.add(columnsFrom[9]);
      columnsTo.add('false');
      columnsTo.add('Order');
      columnsTo.add('');
      columnsTo.add(dateConvert(columnsFrom[10]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[9]); // reference
      return columnsTo;

    case FileType.finDocOrderPurchaseItem:
      // 1:vendorId 2:vendorName, 9:order id, 10:date(mm/dd/yy),
      // 11:closed(TRUE/FALSE) 27: seq number, 28: quantity, 29: productId,
      // 30: descr, 31: accountCode, 32: price, 33: amount
      if (columnsFrom.length < 33) return [];

      columnsTo.add(columnsFrom[9]); // will be replaced by sequential id
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
      // 16:discountAmount, 17: total amount, 22: orderId,
      // 7: item number, 24: quantity, 25: productId,
      // 26: descr, 27: accountCode, 28: price, 29: amount, 30: terms
      if (columnsFrom.length < 18) return [];

      // just use to combine items, need to replace by seq num
      columnsTo.add(columnsFrom[3]); // will be replaced by sequential id
      columnsTo.add('false');
      columnsTo.add('Invoice');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[5]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]); // put refnum here
      columnsTo.add('');
      columnsTo.add(columnsFrom[17]); // total amount
      return columnsTo;

    case FileType.finDocInvoicePurchaseItem:
      // 1:vendorId 2:vendorName, 3:reference, 4:creditMemo 5:date(mm/dd/yy),
      // 16:discountAmount, 22: orderId,
      // 7: item number, 24: quantity, 25: productId,
      // 26: descr, 27: accountCode, 28: price, 29: amount, 30: terms
      if (columnsFrom.length < 28) return [];
      columnsTo.add(columnsFrom[3]); // will be replaced by sequential id
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
      if (columnsFrom.length < 21) return [];
      // date/checknumber is key here because checknumber is reference in ledger
      columnsTo.add(
          "${dateConvert(columnsFrom[11])}-${columnsFrom[10]}"); // will be replaced by sequential id
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
      columnsTo.add(columnsFrom[10]); // checknumber
      String amount = columnsFrom[14].replaceAll('-', ''); // check number
      columnsTo.add(amount); // total amount
      if (amount == '0' || amount == '' || double.tryParse(amount) == null)
        return []; // ignore records with zero/invalid amounts
      columnsTo.add(columnsFrom[20]); // for invoice in classification
      return columnsTo;

    case FileType.finDocPaymentPurchaseItem: // just a single record for amount
      // 1:vendorId 2:vendorName, 3:checkname, 10: checkNumber, 11:date(mm/dd/yy),
      // 13: cash accountCode, 18: date cleared, 20: invoiceId, 21: discount Amount,
      // 24: productId, 23: quantity, 25: description 26: accountCode, 28: price
      if (columnsFrom.length < 28) return [];
      columnsTo.add(
          "${dateConvert(columnsFrom[11])}-${columnsFrom[10]}"); // will be replaced by sequential id
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

      columnsTo.add(columnsFrom[3]);
      columnsTo.add('true');
      columnsTo.add('Order');
      columnsTo.add('');
      columnsTo.add(dateConvert(columnsFrom[4]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]); // reference invoiceId
      return columnsTo;

    case FileType.finDocOrderSaleItem:
      // 1:custId 2:custName, 3:order id, 4:date(mm/dd/yy),
      // 6:closed(TRUE/FALSE) 21: item number, 22: quantity, 23: productId,
      // 24: descr, 25: accountCode, 26: price, 28: amount
      if (columnsFrom.length < 28) return [];

      columnsTo.add(columnsFrom[3]);
      columnsTo.add('Order');
      columnsTo.add(''); //seqId by system
      columnsTo.add(columnsFrom[23]); // product id
      columnsTo.add(columnsFrom[24]); // descr
      columnsTo.add(columnsFrom[22]); // quant
      columnsTo.add(columnsFrom[26]); // price
      columnsTo.add(columnsFrom[25]); // itemType accountCode
      columnsTo.add('');
      columnsTo.add(accountCodeToItemType(columnsFrom[25], ''));
      return columnsTo;

    case FileType.finDocInvoiceSale:
      // 1:custId 2:custName, 3:reference id, 4: applyInvoiceId 5:creditMemo 6:date(mm/dd/yy),
      // 15: custPO 16:discountAmount, 17: ship date,
      // 28: quantity, 30: productId,
      // 32: descr, 33: accountCode, 34: price, 36: amount, 30: terms

      // just use to combine items, need to replace by seq num
      columnsTo.add(columnsFrom[3]);
      columnsTo.add('true');
      columnsTo.add('Invoice');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[6]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[3]); // put refnum here
      columnsTo.add('');
      columnsTo.add('');
      return columnsTo;

    case FileType.finDocInvoiceSaleItem:
      // 1:custId 2:custName, 3:reference id, 4: applyInvoiceId 5:creditMemo 6:date(mm/dd/yy),
      // 15: custPO 16:discountAmount, 17: ship date,
      // 28: quantity, 30: productId,
      // 32: descr, 33: accountCode, 34: price, 36: amount, 30: terms
      if (columnsFrom.length < 30) return [];
      columnsTo.add(columnsFrom[3]); // will be replaced by sequential id
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
      if (columnsFrom.length < 22) return [];

      columnsTo.add(
          "${dateConvert(columnsFrom[5])}-${columnsFrom[4]}"); // will be replaced by sequential id
      columnsTo.add('true');
      columnsTo.add('Payment');
      columnsTo.add('converted');
      columnsTo.add(dateConvert(columnsFrom[5]));
      columnsTo.add('');
      columnsTo.add(columnsFrom[1]);
      columnsTo.add(columnsFrom[2]);
      columnsTo.add(columnsFrom[4]); // ledger reference
      columnsTo.add('');
      String amount = columnsFrom[21].replaceAll('-', ''); // check number
      columnsTo.add(amount); // total amount
      columnsTo.add(columnsFrom[14]); // for invoice in classification
      return columnsTo;

    case FileType.finDocPaymentSaleItem: // just a single record for amount
      // 0: partyId, 1:custId 2:custName, 3:dep date, 4:reference 6: pay method,
      // 8: amount, 11: paid on invoices,  14: invoiceId paid
      // 16: discount amount, 7: glaccount, 11: discount account 18: rec account
      // 21: amount
      if (columnsFrom.length < 22) return [];
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
      // generate the initial posted balances from the leger organization, if any
      // 1: account code, 2,3 not used here
      // 4: debit amount, 5 credit
      // only do when start date present becaue will also generate timeperiods
      if (columnsFrom[0] == '10100') {
        columnsTo.add(
            "${dateConvert(columnsFrom[2])}-00000"); // will be replaced by sequential id
        columnsTo.add("true");
        columnsTo.add('Transaction');
        columnsTo.add('Initial ledger posted values');
        columnsTo.add(columnsFrom[2].substring(0, 10));
        columnsTo.add('');
        columnsTo.add('');
        columnsTo.add('');
        columnsTo.add(''); // reference
        return columnsTo;
      }
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

      // create initial transaction from ledger
      // generate the initial posted balances from the leger organization, if any
      // 1: account code, 2,3 not used here
      // 5: debit amount, 6 credit amount

      bool isDebit = true;
      var amount = columnsFrom[6];
      if (columnsFrom[7].isNotEmpty) {
        isDebit = false;
        amount = columnsFrom[7];
      }

      // posting balance
      if (columnsFrom[5] == 'Beginning Balance' && columnsFrom[8] != '') {
        columnsTo.add("${dateConvert(columnsFrom[2])}-00000}");
        columnsTo.add('Transaction');
        columnsTo.add('');
        columnsTo.add('');
        columnsTo.add(columnsFrom[5]); // descr
        columnsTo.add('');
        columnsTo.add(columnsFrom[8]);
        columnsTo.add(columnsFrom[0]); // account code
        columnsTo.add(''); // get isDebit from account setting
        return columnsTo;
      }

      // 0: accountId, 2:date, 3:reference, 6: debit amount, 7 credit amount,
      // 17: productId, 18: line description,
      if (columnsFrom.length < 19) return [];

      isDebit = true;
      amount = columnsFrom[6];
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
      columnsTo.add(columnsFrom[0]); // account code
      columnsTo.add(isDebit.toString());
      return columnsTo;
    // do some more conversion here, depending on filetype.
    //
    default: // no output
      return [];
  }
}

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
