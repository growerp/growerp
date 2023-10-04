/// an example program to make any csv file suitable
/// to be imported into GrowERP.
///
/// Its reordering columns an incoming CSV doing optional
/// required conversion in the process
///
/// input parameter:
/// 1. the input filename or directory
/// the filename determines the type of data.
/// if a directory all filenames in that directory will be processed
///

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models_new/growerp_models_new.dart';
import '../get_files.dart';

String outputDirectory = 'growerp';
Map convertClass = {
  'Accounts Payable': 'Accounts Payable',
  'Accounts Receivable': 'Accounts Receivable',
  'Accumulated Depreciation': 'Accumulated Depreciation',
  'Expenses': 'Accrued Expenses',
  'Fixed Assets': 'Land and Building',
  'Income': 'Cash Income',
  'Cash': 'Cash and Equivalent',
  'Inventory': 'Inventory Assets',
  'Cost of Sales': 'Cost of Sales',
  'Long Term Liabilities': 'Long Term Liabilities',
  'Equity - doesn\'t close (Corporation)': 'Owners Equity',
  'Other Assets': 'Other Assets',
  'Equity-gets closed': 'Equity Distribution',
  'Other Current Assets': 'Other Assets',
  'Equity-Retained Earnings': 'Retained Earnings',
  'Other Current Liabilities': 'Current Liabilities',
  'Payables Retainage (Sage 50 Quantum Accounting)': '',
  'Receivables Retainage (Sage 50 Quantum Accounting)': '',
};
List<String> convertRow(FileType fileType, List<String> columnsFrom) {
  List<String> columnsTo = [];
  switch (fileType) {
    case FileType.glAccount:
      columnsTo.add(columnsFrom[0]); //0 accountCode
      columnsTo.add(columnsFrom[2]); //1 account name
      columnsTo.add(convertClass[columnsFrom[1]]); //2 class
      columnsTo.add(''); //3 type empty
      columnsTo.add(columnsFrom[3].isNotEmpty //4 balance
          ? columnsFrom[3].replaceAll(',', '')
          : columnsFrom[4].replaceAll(',', ''));
      return columnsTo;
    //
    // do some conversion here, depending on filetype.
    //
    default: // no output
      return [];
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    print("Specify a filename or directory");
    exit(1);
  }
  List<String> files = getFiles(args[0]);
  if (files.isEmpty) exit(1);
  if (isDirectory(outputDirectory)) {
    print("output directory $outputDirectory already exists, do not overwrite");
    exit(1);
  }
  createDir(outputDirectory);

  for (String fileInput in files) {
    // parse raw csv file string
    String lines = File(fileInput).readAsStringSync();
    FileType fileType = getFileType(fileInput);
    final csvFile = fast_csv.parse(lines);
    final file = File("$outputDirectory/${fileType.name}.csv");
    List<String> fileContent = [];
    switch (fileType) {
      case FileType.glAccount:
        fileContent.add(GlAccountCsvFormat());
        break;
      default:
        fileContent.add("header is missing");
    }
    for (final row in csvFile) {
      if (row == csvFile.first || row[0].isEmpty) continue;
      fileContent.add(createCsvRow(convertRow(fileType, row)));
    }
    file.writeAsStringSync(fileContent.join());
    exit(0);
  }
}
