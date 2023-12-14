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
Map convertClass = {
  '1': 'Accounts Receivable',
  'Accounts Receivable': 'Accounts Receivable',
  '2': 'Inventory Assets',
  'Inventory': 'Inventory Assets',
  '4': 'Other Assets',
  'Other Current Assets': 'Other Assets',
  '5': 'Land and Building',
  'Fixed Assets': 'Land and Building',
  '6': 'Accumulated Depreciation',
  'Accumulated Depreciation': 'Accumulated Depreciation',
  '8': 'Other Assets',
  'Other Assets': 'General Other Assets',
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
  '21': 'Cash Income',
  'Income': 'Cash Income',
  '23': 'Cost of Sales',
  'Cost of Sales': 'Cost of Sales',
  '24': 'Operating Expense',
  'Expenses': 'Operating Expense',
  '98': 'Discounts and Write-downs',
  '0': 'Cash and Equivalent',
  'Cash': 'Cash and Equivalent',
  '99': 'Goods Revenue',
  '16': 'Owners Equity',
  '97': 'Customer Returns',
  'Sales Discounts': 'Discounts and Write-downs',
};
List<String> convertRow(
    FileType fileType, List<String> columnsFrom, String fileName) {
  List<String> columnsTo = [];
  switch (fileType) {
    /// convert to [glAccountCsvFormat]
    case FileType.glAccount:
      // remove empty and double id's
      if (columnsFrom[0] == '' || ids.contains(columnsFrom[0])) return [];
      ids.add(columnsFrom[0]);
      columnsTo.add(columnsFrom[0]); //0 accountCode
      columnsTo.add(columnsFrom[2]); //1 account name
      // need to revers column name for different files
      // this one for Trial_Balan...
      columnsTo.add(convertClass[columnsFrom[1]]); //2 class
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
      if (columnsFrom[18] != '' && !ids.contains(columnsFrom[18])) {
        ids.add(columnsFrom[18]);
        columnsTo.add(columnsFrom[18]); // id
        columnsTo.add('Physical Good'); // type
        columnsTo.add(columnsFrom[19]); // name
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
      }
      return columnsTo;

    /// convert to [companyCsvFormat]
    case FileType.company:
      if (fileName.contains('customer')) {
        // 0:partyId,partyType,Customer ID,Customer Name,Inactive,
        // 5:Bill to Address-Line One,Bill to Address-Line Two,Bill to City,
        // 8:Bill to State,Bill to Zip,Bill to Country,Bill to Sales Tax ID,
        // 12:Telephone 1,Telephone 2,Fax Number,Customer E-mail,
        // 16:Resale Number,Discount Days,Discount Percent,Customer Web Site
        columnsTo.add('');
        columnsTo.add(columnsFrom[2]); // id
        columnsTo.add(Role.customer.value); //role
        columnsTo.add(columnsFrom[3]); //name
        columnsTo.add(columnsFrom[15]); //email
        columnsTo.add(columnsFrom[12]); // teleph
        columnsTo.add('USD'); //curr
        columnsTo.add(''); //image
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
        columnsTo.add('');
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

    case FileType.finDocTransaction:
      // 0: accountId, 2:date, 3:reference, 4:journalId, 5:description,
      // 11: customerId, 13: vendorId, 15: employeeId,

      // convert from m/d/yy to yyyy-mm-dd
      var dateList = (columnsFrom[2]).split('/');
      var prefix;
      if (dateList[2] == '99')
        prefix = '19';
      else
        prefix = '20';
      var newDate =
          "${prefix}${dateList[2]}-${dateList[0].padLeft(2, '0')}-${dateList[1].padLeft(2, '0')}";
      var otherCompanyId = columnsFrom[11].isNotEmpty
          ? columnsFrom[11]
          : columnsFrom[13].isNotEmpty
              ? columnsFrom[13]
              : columnsFrom[15].isNotEmpty
                  ? columnsFrom[15]
                  : '';

      columnsTo.add(columnsFrom[3] == '' ? 'xxxxxx' : columnsFrom[3]);
      columnsTo.add('true');
      columnsTo.add('transaction');
      columnsTo.add(columnsFrom[5]);
      columnsTo.add(newDate);
      columnsTo.add('');
      columnsTo.add(otherCompanyId);
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

      columnsTo.add(columnsFrom[3] == '' ? 'xxxxxx' : columnsFrom[3]);
      columnsTo.add('transaction');
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

String convertFile(FileType fileType, String string, String fileName) {
  switch (fileType) {
    case FileType.glAccount:
      string = string
          .replaceFirst('48000,Sales Returns and Allowances,21',
              '48000,Sales Returns and Allowances,97')
          .replaceFirst('49000,Sales Discounts,21', '49000,Sales Discounts,98')
          .replaceFirst('89500,Discount for Early Payment,23',
              '89500,Discount for Early Payment,99');
      string = string
          .replaceFirst('48000","Income","Sales Returns and Allowances',
              '48000","97","Sales Returns and Allowances')
          .replaceFirst('49000","Income","Sales Discounts',
              '49000","98","Sales Discounts')
          .replaceFirst('89500","Cost of Sales","Discount for Early Payment',
              '89500","99","Discount for Early Payment');
      break;
    default:
  }
  return string;
}

Future<void> main(List<String> args) async {
  var logger = Logger(filter: MyFilter());
  if (args.isEmpty) {
    logger.e(
        "Specify a directory and optionally a filetype like: ${FileType.values}?");
    exit(1);
  }

  if (isDirectory(outputDirectory)) {
    logger.e(
        "output directory $outputDirectory already exists, cannot overwrite");
    exit(1);
  }
  createDir(outputDirectory);

  for (var fileType in FileType.values) {
    if (fileType == FileType.unknown) continue;
    if (args.length == 2 && fileType.name != args[1]) continue;
    List<String> fileContent = [];
    List<List<String>> convertedRows = [];
    // define search file names for every filetype
    List<String> searchFiles = [];
    switch (fileType) {
      case FileType.glAccount:
        // searchFile = '4-1-chart_of_accounts_list.csv';
        searchFiles.add('Trial_Balance_2020-06-07.csv');
        break;
      case FileType.company:
        searchFiles.add('1-3-customer_list.csv');
        searchFiles.add('2-3-vendor_list.csv');
        break;
      default:
        searchFiles.add('0b*.csv');
    }
    if (searchFiles.isEmpty) continue;
    // list of files to process
    List<String> files = [];
    for (String searchFile in searchFiles) {
      files.addAll(find(searchFile, workingDirectory: args[0]).toList());
    }
    if (files.isEmpty) {
      logger.e(
          "No ${searchFiles.join()} csv files found in directory ${args[0]}");
      exit(1);
    }
    // process files and convert rows
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
        List<String> convertedRow = convertRow(fileType, row, fileInput);
        // print("==old: $row new: $convertedRow");
        if (convertedRow.isNotEmpty) convertedRows.add(convertedRow);
      }
    }
    // print("==2==${convertedRows.length} 0:${convertedRows[0]}");

    int csvLength = 0;
    // prepare output files and run post processing like sort
    switch (fileType) {
      case FileType.glAccount:
        fileContent.add(glAccountCsvFormat);
        csvLength = glAccountCsvLength;
        break;
      case FileType.category:
        fileContent.add(categoryCsvFormat);
        csvLength = categoryCsvLength;
        break;
      case FileType.product:
        fileContent.add(productCsvFormat);
        csvLength = productCsvLength;
        break;
      case FileType.company:
        fileContent.add(companyCsvFormat);
        csvLength = companyCsvLength;
        break;
      case FileType.user:
        fileContent.add(userCsvFormat);
        csvLength = userCsvLength;
        break;
      case FileType.finDocTransaction:
        fileContent.add(finDocCsvFormat);
        csvLength = finDocCsvLength;
        // sort better use maps for empty values
        convertedRows.sort((a, b) =>
            "${a.asMap()[4] ?? ''}${a.asMap()[0] ?? ''}"
                .compareTo("${b.asMap()[4] ?? ''}${b.asMap()[0] ?? ''}"));
        // remove detail lines
        List<String> lastRow = [];
        List<List<String>> headerRows = [];
        for (final row in convertedRows) {
          if (row.isEmpty) continue;
          if (row.isEmpty || lastRow.isEmpty || row[0] != lastRow[0])
            headerRows.add(row);
          lastRow = row;
        }
        if (lastRow.isNotEmpty) headerRows.add(lastRow);
        convertedRows = headerRows;
        break;
      case FileType.finDocTransactionItem:
        fileContent.add(finDocItemCsvFormat);
        csvLength = finDocItemCsvLength;
        // sort better use maps for empty values
        convertedRows
            .sort((a, b) => (a.asMap()[0] ?? '').compareTo(b.asMap()[0] ?? ''));
        break;
      default:
    }
    // create csv output file
    for (final convertedRow in convertedRows) {
      fileContent.add(createCsvRow(convertedRow, csvLength));
    }
    // write to disk
    if (fileContent.length > 1) {
      final file = File("$outputDirectory/${fileType.name}.csv");
      file.writeAsStringSync(fileContent.join());
    }
  }
  exit(0);
}
