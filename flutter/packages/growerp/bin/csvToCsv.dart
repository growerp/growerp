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
import 'package:growerp_models_new/growerp_models_new.dart';
import 'package:logger/logger.dart';
import '../file_type_model.dart';
import '../get_file_type.dart';
import '../get_files.dart';
import '../logger.dart';

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
    logger.e("Specify a filename or directory");
    exit(1);
  }
  FileType? fileType;
  if (args[1].isNotEmpty) {
    fileType = getFileType(args[1]);
  }
  List<String> files =
      getFiles(args[0], overrrideFileType: getFileType(args[1]));
  if (files.isEmpty) exit(1);
  if (isDirectory(outputDirectory)) {
    logger.e(
        "output directory $outputDirectory already exists, cannot overwrite");
    exit(1);
  }
  createDir(outputDirectory);

  for (String fileInput in files) {
    // parse raw csv file string
    String contentString = File(fileInput).readAsStringSync();
    fileType = fileType ?? getFileType(fileInput);
    // general changes in content
    contentString = convertFile(fileType, contentString);
    final csvFile = fast_csv.parse(contentString);
    final file = File("$outputDirectory/${fileType.name}.csv");
    List<String> fileContent = [];
    switch (fileType) {
      case FileType.glAccount:
        fileContent.add(GlAccountCsvFormat());
        break;
      case FileType.category:
        fileContent.add(CategoryCsvFormat());
        break;
      case FileType.product:
        fileContent.add(ProductCsvFormat());
        break;
      case FileType.company:
        fileContent.add(CompanyCsvFormat());
        break;
      case FileType.user:
        fileContent.add(UserCsvFormat());
        break;
      case FileType.finDocTransaction:
        fileContent.add(FinDocTransactionCsvFormat());
        break;
      default:
        fileContent.add(" ${fileType.name} not supported yet");
    }
    for (final row in csvFile) {
      if (row == csvFile.first || row[0].isEmpty) continue;
      fileContent.add(createCsvRow(convertRow(fileType, row)));
    }
    file.writeAsStringSync(fileContent.join());
  }
  exit(0);
}
