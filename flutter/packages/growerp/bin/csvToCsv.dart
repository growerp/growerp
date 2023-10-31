/// an example program to make any csv file suitable
/// to be imported into GrowERP.
///
/// Its reordering columns and incoming CSV doing optional
/// required conversion in the process
///
/// input parameter:
/// 1. the input directory with the filenames defined in this program
///
/// run this program with:
///   dart run ~/growerp/flutter/packages/growerp/bin/csvToCsv.dart inputDir
///   will create a new directory: growerpOutput with the converted file.

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
List<String> convertRow(FileType fileType, List<String> columnsFrom) {
  List<String> columnsTo = [];
  switch (fileType) {
    case FileType.glAccount:
      if (columnsFrom[0] == '' || ids.contains(columnsFrom[0])) return [];
      ids.add(columnsFrom[0]);
      columnsTo.add(columnsFrom[0]); //0 accountCode
      columnsTo.add(columnsFrom[2]); //1 account name
      // need to revers column name for different files
      // this one for Trial_Balan...
      print("=====looking for: ${columnsFrom[0]} ${columnsFrom[1]}");
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

    case FileType.company:
      if (columnsFrom[11].isEmpty && columnsFrom[13].isEmpty) return [];
      // ignore when already exist
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
        if (columnsFrom[13] == 'ACCUGEO LINER, INC.') {
          columnsTo.add(Role.company.value);
          columnsTo.add("AccuGeo Liner, Inc.");
        } else {
          columnsTo.add(Role.supplier.value);
          columnsTo.add(columnsFrom[14]);
        }
      }
      if (columnsTo[1] == 'customerId') {
        return [];
      }
      return columnsTo;

    case FileType.user:
      return columnsTo;

    //
    // do some conversion here, depending on filetype.
    //
    default: // no output
      return [];
  }
}

String convertFile(FileType fileType, String string) {
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
      return string;
    default:
      return string;
  }
}

void main(List<String> args) {
  var logger = Logger(filter: MyFilter());
  if (args.isEmpty) {
    logger.e("Specify a directory?");
    exit(1);
  }

  if (isDirectory(outputDirectory)) {
    logger.e(
        "output directory $outputDirectory already exists, cannot overwrite");
    exit(1);
  }
  createDir(outputDirectory);

  for (var fileType in FileType.values) {
    List<String> fileContent = [];
    print("processing filetype: ${fileType.name}");
    // define search file name for every filetype
    String searchFile = '';
    switch (fileType) {
      case FileType.glAccount:
        // searchFile = '4-1-chart_of_accounts_list.csv';
        searchFile = 'Trial_Balance_2020-06-07.csv';
        break;
      default:
        searchFile = '0b*.csv';
    }
    if (searchFile.isEmpty) continue;
    List<String> files = find(searchFile, workingDirectory: args[0]).toList();
    if (files.isEmpty) {
      logger.e("No $searchFile csv files found in directory ${args[0]}");
      exit(1);
    }
    int csvLength = 0;
    // add header in output file
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
        break;
      default:
    }
    for (String fileInput in files) {
      print("processing file: ${fileInput}");
      // parse raw csv file string
      String contentString = File(fileInput).readAsStringSync();

      // general changes in content
      contentString = convertFile(fileType, contentString);

      // parse input file
      final inputCsvFile = fast_csv.parse(contentString);

      // convert rows
      int index = 0;
      for (final row in inputCsvFile) {
        if (++index % 10000 == 0) print("processing row: $index");
        if (row == inputCsvFile.first) continue;
        var convertedRow = convertRow(fileType, row);
        if (convertedRow.isNotEmpty) {
          fileContent.add(createCsvRow(convertedRow, csvLength));
        }
      }
    }
    final file = File("$outputDirectory/${fileType.name}.csv");
    file.writeAsStringSync(fileContent.join());
  }
  exit(0);
}
