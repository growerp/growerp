// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../src.dart';

Future<bool> login(RestClient client, String username, String password,
    {String companyName = '', String currencyId = ''}) async {
  Hive.init('growerpDB');
  var box = await Hive.openBox('growerp');
  late Authenticate authenticate;
  var logger = Logger(filter: MyFilter());
  bool alreadyRegistered = false;

  try {
    // email exists?
    Map result = await client.checkEmail(email: username);
    if (result['ok'] == false) {
      if (username.isNotEmpty &&
          password.isNotEmpty &&
          companyName.isNotEmpty &&
          currencyId.isNotEmpty) {
        // no so register new
        await client.register(
          classificationId: 'AppAdmin',
          email: username,
          newPassword: password,
          firstName: 'admin',
          lastName: 'user',
        );
      } else {
        print("Email adddress not registered yet, however "
            "Without company name and currency you can not register"
            ", use the -n for company name and -c for currency");
        exit(1);
      }
    } else {
      alreadyRegistered = true;
    }
  } catch (e) {
    print("registration failed: ${getDioError(e)}");
  }

  // login
  await client.login(
      username: username, password: password, classificationId: 'AppAdmin');
  // login again to provide more info and get apikey
  authenticate = await client.login(
      username: username,
      password: password,
      classificationId: 'AppAdmin',
      companyName: companyName,
      currencyId: currencyId,
      demoData: false,
      extraInfo: true);
  // save key
  box.put('apiKey', authenticate.apiKey);
  await box.put('authenticate', jsonEncode(authenticate.toJson()));

  logger.i("logged in with admin user: ");
  return alreadyRegistered;
}

import(String inputFile, String? backendUrl, String username, String password,
    String companyName, String currencyId,
    {FileType overrideFileType = FileType.unknown}) async {
  var logger = Logger(filter: MyFilter());
  int timeout = 600; //in seconds

  List<String> files = find('*.csv', workingDirectory: inputFile).toList();
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
    final bool alreadyRegistered = await login(client, username, password,
        companyName: companyName, currencyId: currencyId);
    // import
    for (fileType in FileType.values) {
      if (overrideFileType != FileType.unknown &&
          overrideFileType != fileType) {
        continue;
      }
      var fileNames =
          find('${fileType.name}-*.csv', workingDirectory: inputFile).toList();
      fileNames.sort();
      for (final fileName in fileNames) {
        logger.i("Importing $fileType: $fileName");
        String csvFile = File(fileName).readAsStringSync();
        if (!alreadyRegistered) {}
        switch (fileType) {
          case FileType.itemType:
            if (!alreadyRegistered) {
              await client.importItemTypes(csvToItemTypes(csvFile));
            }
          case FileType.paymentType:
            if (!alreadyRegistered) {
              await client.importPaymentTypes(csvToPaymentTypes(csvFile));
            }
          case FileType.glAccount:
            if (!alreadyRegistered) {
              await client.importGlAccounts(csvToGlAccounts(csvFile));
            }
          case FileType.product:
            if (!alreadyRegistered) {
              await client.importProducts(
                  csvToProducts(csvFile, logger), 'AppAdmin');
            }
          case FileType.category:
            if (!alreadyRegistered) {
              await client.importCategories(csvToCategories(csvFile));
            }
          case FileType.asset:
            if (!alreadyRegistered) {
              await client.importAssets(
                  csvToAssets(csvFile, logger), 'AppAdmin');
            }
          case FileType.company:
            if (!alreadyRegistered) {
              await client.importCompanies(csvToCompanies(csvFile));
            }
          case FileType.user:
            if (!alreadyRegistered) {
              await client.importUsers(csvToUsers(csvFile));
            }
          case FileType.website:
            if (!alreadyRegistered) {
              await client.importWebsite(csvToWebsite(csvFile));
            }
          case FileType.finDocTransaction:
          case FileType.finDocOrderSale:
          case FileType.finDocOrderPurchase:
          case FileType.finDocInvoiceSale:
          case FileType.finDocInvoicePurchase:
          case FileType.finDocPaymentSale:
          case FileType.finDocPaymentPurchase:
          case FileType.finDocShipmentIncoming:
          case FileType.finDocShipmentOutgoing:
            await client.importFinDoc(csvToFinDocs(csvFile, logger));
          case FileType.finDocTransactionItem:
          case FileType.finDocOrderSaleItem:
          case FileType.finDocOrderPurchaseItem:
          case FileType.finDocInvoiceSaleItem:
          case FileType.finDocInvoicePurchaseItem:
          case FileType.finDocPaymentSaleItem:
          case FileType.finDocPaymentPurchaseItem:
          case FileType.finDocShipmentOutgoingItem:
          case FileType.finDocShipmentIncomingItem:
            await client.importFinDocItem(
                csvToFinDocItems(csvFile, logger), 'AppAdmin');
          default:
            logger.e("FileType ${fileType.name} not implemented yet");
            exit(1);
        }
      }
    }
    // recalculate ledger totals
    await client.calculateLedger();
  } on DioException catch (e) {
    logger.e("Importing filetype: ${fileType.name} Error: ${getDioError(e)}");
  }
}
