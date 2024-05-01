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
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../lib/src/src.dart';

var logger = Logger(filter: MyFilter());
String outputDirectory = 'growerpOutput';

Future<void> main(List<String> args) async {
  var logger = Logger(filter: MyFilter());
  DateTime? startDate, endDate;
  FileType? requestedFileType;

  DateTime convertDateString(dateString) {
    // format yyyy/mm/dd
    return DateTime.parse("${dateString.substring(0, 4)}-"
        "${dateString.substring(5, 7)}-${dateString.substring(8, 10)} 00:00:00.000");
  }

  if (args.isEmpty) {
    logger.e("Need at least a directory name with the GrowERP CSV formatted "
        "files, and optionally:\n -f a fileType\n -start start date in "
        "format yyyy/mm/dd\n -end and enddate in the same format");
    exit(1);
  } else {
    final modifiedArgs = <String>[];
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '-start':
          startDate = DateTime.parse("${args[++i].substring(0, 4)}-"
              "${args[i].substring(5, 7)}-${args[i].substring(8, 10)} 00:00:00.000");
          break;
        case '-end':
          endDate = DateTime.parse("${args[++i].substring(0, 4)}-"
              "${args[i].substring(5, 7)}-${args[i].substring(8, 10)} 00:00:00.000");
          break;
        case '-f':
          i++;
          requestedFileType = FileType.values.firstWhere(
              (e) => e.name == args[i],
              orElse: () => FileType.unknown);
          if (requestedFileType == FileType.unknown) {
            logger.e("Filetype: ${args[i]}  not recognized");
            exit(1);
          }
          break;
        default:
          modifiedArgs.add(args[i]);
      }
    }

    if (modifiedArgs.length > 1) {
      logger.e("unrecognized argument: ${modifiedArgs[1]}");
      exit(1);
    }
    var outputDirectory = modifiedArgs[0];
    logger.i("csvToCsv command: directory ${outputDirectory} "
        "startDate: ${startDate.toString()}  "
        "endDate: ${endDate.toString()} -f ${requestedFileType?.name}");
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

  // process file types
  for (var fileType in FileType.values) {
    if (fileType == FileType.unknown) continue;
    if (requestedFileType != null && fileType != requestedFileType) continue;
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
          "No ${searchFiles.join()} files found in directory ${args[0]}, skipping");
    }

    // convert from CSV or XLSX or ODF to CSV rows
    List<List<String>> inputCsvFile = [];
    List<List<String>> convertedRows = [];
    for (String fileInput in files) {
      String fileContent = '';
      logger.i("Processing filetype: ${fileType.name} file: ${fileInput}");
      if (fileInput.endsWith('.csv')) {
        // parse raw csv file string
        fileContent = File(fileInput).readAsStringSync();
      }
      if (fileInput.endsWith('.ods') || fileInput.endsWith('.xlsx')) {
        // convert spreadsheet to csv
        var bytes = File(fileInput).readAsBytesSync();
        var decoder = SpreadsheetDecoder.decodeBytes(bytes);
        final buffer = StringBuffer();
        decoder.tables.forEach((key, value) {
          value.rows.forEach((row) {
            List<String> rows = [];
            row.forEach((element) {
              rows.add(element == null ? '' : '$element');
            });
            buffer.write(createCsvRow(rows, row.length));
          });
        });
        fileContent = buffer.toString();
      }
      // general changes in content
      fileContent = convertFile(fileType, fileContent, fileInput);
      // parse input file and convert rows
      int index = 0;
      inputCsvFile = fast_csv.parse(fileContent);
      for (final row in inputCsvFile) {
        if (++index % 10000 == 0) print("processing row: $index");
        if (fileInput.endsWith('.csv') && row == inputCsvFile.first)
          continue; // header line
        List<String> convertedRow =
            convertCsvRow(fileType, row, fileInput, images, startDate);
        if (convertedRow.isNotEmpty) convertedRows.add(convertedRow);
      }
      logger.i(
          "filetype: ${fileType.name} file: ${fileInput} $index records processed");
    }

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
          if (startDate != null &&
              convertDateString(row[0]).isBefore(startDate)) continue;
          if (endDate != null && convertDateString(row[0]).isAfter(endDate))
            continue;
          if (row[0].isEmpty) continue;
          if (lastRow.isEmpty || row[0] != lastRow[0]) {
            List<String> newRow = List.from(row);
            // replace by sequential number
            newRow[0] = (seqNumber++).toString();
            print(
                "==T=new row: ${newRow[0]} ${newRow[8]} ===oldrow: ${row[0]} ${row[8]}");
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
        List<List<String>> itemRows = [];
        List<String> lastRow = [];
        int seqNumber = 10000;
        for (final row in convertedRows) {
          if (startDate != null &&
              convertDateString(row[0]).isBefore(startDate)) continue;
          if (endDate != null && convertDateString(row[0]).isAfter(endDate))
            continue;
          if (lastRow.isNotEmpty && row[0] != lastRow[0]) {
            seqNumber++;
          }
          List<String> newRow = List.from(row);
          newRow[0] = seqNumber.toString();
          print(
              "==I=new row: ${newRow[0]} ${newRow[8]} ===oldrow: ${row[0]} ${row[8]}");
          itemRows.add(newRow);
          lastRow = row;
        }
        convertedRows = itemRows;
        // sort better use maps for empty values
        // sort by just reference number
        break;
      default:
    }

    // create csv content
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

    // add csv header and save file
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
