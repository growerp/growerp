#!/usr/bin/env dcli
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

import 'dart:convert';
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../lib/src/src.dart';

Future<void> main(List<String> args) async {
  String growerpPath = '$HOME/growerp';
  String validCommands =
      "valid commands are:'install | import | export | finalize'";
  String? backendUrl;
  String branch = 'master';
  String inputFile = '';
  String username = '';
  String password = '';
  int timeout = 600; //in seconds
  String outputDirectory = 'growerpCsv';
  FileType overrideFileType = FileType.unknown;
  Hive.init('growerpDB');
  late Authenticate authenticate;
  var logger = Logger(filter: MyFilter());
  var box = await Hive.openBox('growerp');

  if (args.isEmpty) {
    logger.e('Please enter a GrowERP command? $validCommands');
    exit(1);
  } else {
    final modifiedArgs = <String>[];
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '-dev':
          branch = 'development';
          break;
        case '-url':
          backendUrl = args[++i];
          break;
        case '-i':
          inputFile = args[++i];
          break;
        case '-u':
          username = args[++i];
          break;
        case '-p':
          password = args[++i];
          break;
        case '-o':
          outputDirectory = args[++i];
        case '-t':
          timeout = int.parse(args[++i]);
          break;
        case '-f':
          i++;
          overrideFileType = FileType.values.firstWhere(
              (e) => e.name == args[i],
              orElse: () => FileType.unknown);
          if (overrideFileType == FileType.unknown) {
            logger.e("Filetype: ${args[i]}  not recognized");
            exit(1);
          }
          break;
        default:
          modifiedArgs.add(args[i]);
      }
    }
    logger.i(
        "Growerp command: ${modifiedArgs[0].toLowerCase()} i: $inputFile u: $username p: $password -branch: $branch -f ${overrideFileType.name}");

    Future<void> login(RestClient client) async {
      if (username.isNotEmpty && password.isNotEmpty) {
        // email exists?
        Map result = await client.checkEmail(email: username);
        if (result['ok'] == false) {
          // no so register new
          await client.registerCompanyAdmin(
              emailAddress: username,
              companyEmailAddress: 'q$username',
              newPassword: password,
              firstName: 'Hans',
              lastName: 'Jansen',
              companyName: 'test company',
              currencyId: 'USD',
              demoData: false,
              classificationId: 'AppAdmin');
        }
        // login for key
        authenticate = await client.login(
            username: username,
            password: password,
            classificationId: 'AppAdmin');
        // save key
        box.put('apiKey', authenticate.apiKey);
        await box.put('authenticate', jsonEncode(authenticate.toJson()));
      } else {
        // get authenticate
        String? result = box.get('authenticate');
        if (result != null) {
          authenticate =
              Authenticate.fromJson({'authenticate': jsonDecode(result)});
        }
      }
    }

    // commands
    if (modifiedArgs.isEmpty) {
      logger.e("No growerp subcommand found.");
    }
    switch (modifiedArgs[0].toLowerCase()) {
      case 'install':
        install(growerpPath, branch);
        break;

      //============================= import =================================
      case 'import':
        List<String> files =
            find('*.csv', workingDirectory: inputFile).toList();
        if (files.isEmpty) {
          logger.e(
              "no files found to process, use the -i directive for the directory?");
          exit(1);
        }
        // talk to backend
        final client = RestClient(await buildDioClient(backendUrl,
            timeout: Duration(seconds: timeout), miniLog: true));
        FileType fileType = FileType.unknown;
        try {
          await login(client);
          // import
          for (fileType in FileType.values) {
            if (overrideFileType != FileType.unknown &&
                overrideFileType != fileType) continue;
            var fileNames =
                find('${fileType.name}-*.csv', workingDirectory: inputFile)
                    .toList();
            fileNames..sort();
            for (final fileName in fileNames) {
              logger.i("Importing $fileType: ${fileName} with admin user: "
                  "${authenticate.user?.email}");
              String csvFile = File(fileName).readAsStringSync();
              switch (fileType) {
                case FileType.itemType:
                  await client.importItemTypes(CsvToItemTypes(csvFile));
                  break;
                case FileType.paymentType:
                  await client.importPaymentTypes(CsvToPaymentTypes(csvFile));
                  break;
                case FileType.glAccount:
                  await client.importGlAccounts(CsvToGlAccounts(csvFile));
                  break;
                case FileType.product:
                  await client.importProducts(
                      CsvToProducts(csvFile, logger), 'AppAdmin');
                  break;
                case FileType.category:
                  await client.importCategories(CsvToCategories(csvFile));
                  break;
                case FileType.asset:
                  await client.importAssets(
                      CsvToAssets(csvFile, logger), 'AppAdmin');
                  break;
                case FileType.company:
                  await client.importCompanies(CsvToCompanies(csvFile));
                  break;
                case FileType.user:
                  await client.importUsers(CsvToUsers(csvFile));
                  break;
                case FileType.website:
                  await client.importWebsite(CsvToWebsite(csvFile));
                  break;
                case FileType.finDocTransaction:
                case FileType.finDocOrderPurchase:
                case FileType.finDocInvoicePurchase:
                case FileType.finDocPaymentPurchase:
                case FileType.finDocOrderSale:
                case FileType.finDocInvoiceSale:
                case FileType.finDocPaymentSale:
                  await client.importFinDoc(CsvToFinDocs(csvFile, logger));
                  break;
                case FileType.finDocTransactionItem:
                case FileType.finDocOrderPurchaseItem:
                case FileType.finDocInvoicePurchaseItem:
                case FileType.finDocPaymentPurchaseItem:
                case FileType.finDocOrderSaleItem:
                case FileType.finDocInvoiceSaleItem:
                case FileType.finDocPaymentSaleItem:
                  await client.importFinDocItem(
                      CsvToFinDocItems(csvFile, logger), 'AppAdmin');
                  break;
                default:
                  logger.e("FileType ${fileType.name} not implemented yet");
                  exit(1);
              }
            }
          }
        } on DioException catch (e) {
          logger.e(
              "Importing filetype: ${fileType.name} Error: ${getDioError(e)}");
        }
        break;
      //===================== finalize imported documents=====================
      case 'finalize':
        final client = RestClient(await buildDioClient(backendUrl,
            timeout: Duration(seconds: timeout), miniLog: true));
        await login(client);
        client.finalizeImport();
        break;
      //============================= export =================================
      case 'export':
        FileType fileType = FileType.unknown;
        if (modifiedArgs.length > 1) {
          try {
            fileType = FileType.values.byName(modifiedArgs[1]);
          } catch (e) {
            logger.e(
                "invalid file type: ${modifiedArgs[1]}, valid types: ${FileType.values.join().replaceAll('FileType.', ',').replaceAll(',unknown', '')}");
            exit(1);
          }
        }
        final client = RestClient(await buildDioClient(backendUrl,
            timeout: Duration(seconds: timeout)));
        try {
          if (isDirectory(outputDirectory)) {
            logger.e(
                "output directory $outputDirectory already exists, do not overwrite");
            exit(1);
          }
          createDir(outputDirectory);
          if (username.isNotEmpty && password.isNotEmpty) {
            await login(client);
          }
          String csvContent = '';
          // export glAccount
          if (fileType == FileType.unknown || fileType == FileType.glAccount) {
            GlAccounts result = await client.getGlAccount(limit: 999);
            csvContent = CsvFromGlAccounts(result.glAccounts);
            final file1 =
                File("$outputDirectory/${FileType.glAccount.name}.csv");
            file1.writeAsStringSync(csvContent);
          }
          // export company
          if (fileType == FileType.unknown || fileType == FileType.company) {
            Companies result = await client.getCompany(limit: 999);
            csvContent = CsvFromCompanies(result.companies);
            final file2 = File("$outputDirectory/${FileType.company.name}.csv");
            file2.writeAsStringSync(csvContent);
          }
          // export users
          if (fileType == FileType.unknown || fileType == FileType.user) {
            Users result = await client.getUsers('999');
            csvContent = CsvFromUsers(result.users);
            final file3 = File("$outputDirectory/${FileType.user.name}.csv");
            file3.writeAsStringSync(csvContent);
          }
          // export products
          if (fileType == FileType.unknown || fileType == FileType.product) {
            Products result = await client.getProducts(limit: 999);
            csvContent = CsvFromProducts(result.products);
            final file4 = File("$outputDirectory/${FileType.product.name}.csv");
            file4.writeAsStringSync(csvContent);
          } // export categories
          if (fileType == FileType.unknown || fileType == FileType.category) {
            fileType = FileType.category;
            Categories result = await client.getCategories(limit: 999);
            csvContent = CsvFromCategories(result.categories);
            final file5 =
                File("$outputDirectory/${FileType.category.name}.csv");
            file5.writeAsStringSync(csvContent);
          }
          // export website
          if (fileType == FileType.unknown || fileType == FileType.website) {
            fileType = FileType.website;
            Website result = await client.exportWebsite();
            csvContent = CsvFromWebsite(result);
            final file6 = File("$outputDirectory/${FileType.website.name}.csv");
            file6.writeAsStringSync(csvContent);
          }
        } on DioException catch (e) {
          logger.e("Exporting filetype: $fileType Error: ${getDioError(e)}");
        }
        break;
      case 'report':
      // TODO(hansbak): create a data (conversion) report
      // how many open documents order,invoices, payments  value
      // how many orders with no invoices
      // how many invoices with no ledger tranactions
      // etc, etc..
      default:
        logger.e("${modifiedArgs[0]} not a valid subcommand");
    }
  }
}
