/// an example program to make any csv file suitable
/// to be imported into GrowERP.
///
/// Its reordering columns and incoming CSV doing optional
/// required conversion in the process
///
/// input parameter:
/// 1. the input filename or directory
/// the filename determines the type of data.
/// if a directory, all csv filenames in that directory will be processed
/// 2. if a filename is provided an optional filetype can be given when
/// the system cannot get the fileType from the filename
///
/// run this program with:
///   dart run ~/growerp/flutter/packages/growerp/bin/csvToCsv.dart input
///   will create a new directory: growerpOutput with the converted file.

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';
import '../file_type_model.dart';
import '../get_file_type.dart';
import '../get_files.dart';
import '../logger.dart';

var logger = Logger(filter: MyFilter());
List<String> ids = []; //keep id's to avoid duplicates
String outputDirectory = 'growerpOutput';
// convert accountclass, the field that specifies debit/credit
// Debit and Credit are accepted values.
// this map first value is converted to the second value
// with convertClass[inputvalue] gives: outputValue
Map convertClass = {
  'Accounts Payable': 'Accounts Payable',
  'Accounts Receivable': 'Accounts Receivable',
  'Accumulated Depreciation': 'Accumulated Depreciation',
  'Expenses': 'Operating Expense',
  'Fixed Assets': 'Land and Building',
  'Income': 'Cash Income',
  'Income (contra)': 'Discounts and Write-downs',
  'Cash': 'Cash and Equivalent',
  'Inventory': 'Inventory Assets',
  'Cost of Sales': 'Cost of Sales',
  'Cost of Sales (contra)': 'Goods Revenue',
  'Long Term Liabilities': 'Long Term Liabilities',
  'Equity - doesn\'t close (Corporation)': 'Owners Equity',
  'Other Assets': 'Other Assets',
  'Equity-gets closed': 'Equity Distribution',
  'Other Current Assets': 'Other Assets',
  'Equity-Retained Earnings': 'Retained Earnings',
  'Other Current Liabilities': 'Current Liabilities',
  'Payables Retainage (Sage 50 Quantum Accounting)': '',
  'Receivables Retainage (Sage 50 Quantum Accounting)': '',
  'Sales Returns and Allowances': 'Customer Returns',
  'Sales Discounts': 'Discounts and Write-downs',
};
List<String> convertRow(FileType fileType, List<String> columnsFrom) {
  List<String> columnsTo = [];
  switch (fileType) {
    case FileType.glAccount:
      columnsTo.add(columnsFrom[0]); //0 accountCode
      columnsTo.add(columnsFrom[2]); //1 account name
      columnsTo.add(convertClass[columnsFrom[1]]); //2 class
//      columnsTo.add(columnsFrom[1]); //2 class
      columnsTo.add(''); //3 type empty
      if (columnsFrom.length > 2) {
        columnsTo.add(columnsFrom[3].isNotEmpty //4 balance
            ? columnsFrom[3].replaceAll(',', '')
            : columnsFrom[4].replaceAll(',', ''));
      }
      return columnsTo;
    //
    // do some conversion here, depending on filetype.
    //
    default: // no output
      return [];
  }
}

String convertFile(FileType fileType, String string) {
  string = string
      .replaceFirst('48000","Income', '48000","Income (contra)')
      .replaceFirst('49000","Income', '49000","Income (contra)')
      .replaceFirst('89500","Cost of Sales', '89500","Cost of Sales (contra)');
  return string;
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
    ids = [];
    List<String> fileContent = [];
    print("processing filetype: ${fileType.name}");
    // define search file name for every filetype
    String searchFile = '';
    switch (fileType) {
      case FileType.glAccount:
        searchFile = '4-1-chart_of_accounts_list.csv';
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
