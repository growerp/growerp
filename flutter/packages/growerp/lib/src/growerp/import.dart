import 'dart:convert';
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../src.dart';

Future<void> login(RestClient client, String username, String password) async {
  Hive.init('growerpDB');
  var box = await Hive.openBox('growerp');
  late Authenticate authenticate;
  var logger = Logger(filter: MyFilter());

  if (username.isNotEmpty && password.isNotEmpty) {
    // email exists?
    Map result = await client.checkEmail(email: username);
    if (result['ok'] == false) {
      // no so register new
      Map registerResult = await client.registerCompanyAdmin(
          emailAddress: username,
          companyEmailAddress: 'q$username',
          newPassword: password,
          firstName: 'Hans',
          lastName: 'Jansen',
          companyName: 'test company',
          currencyId: 'USD',
          demoData: false,
          classificationId: 'AppAdmin');
      if (registerResult['ok'] == false) {
        logger.e(
            "registration of a new company failed!\nPlease contact support@growerp.com");
        exit(1);
      } else {
        // wait for background server job to finish
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // login for key
    authenticate = await client.login(
        username: username, password: password, classificationId: 'AppAdmin');
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
  logger.i("logged in with admin user: "
      "${authenticate.user?.email}");
}

import(String inputFile, String? backendUrl, String username,
    String password) async {
  FileType overrideFileType = FileType.unknown;
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
    await login(client, username, password);
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
        switch (fileType) {
          case FileType.itemType:
            await client.importItemTypes(csvToItemTypes(csvFile));
          case FileType.paymentType:
            await client.importPaymentTypes(csvToPaymentTypes(csvFile));
          case FileType.glAccount:
            await client.importGlAccounts(csvToGlAccounts(csvFile));
          case FileType.product:
            await client.importProducts(
                csvToProducts(csvFile, logger), 'AppAdmin');
          case FileType.category:
            await client.importCategories(csvToCategories(csvFile));
          case FileType.asset:
            await client.importAssets(csvToAssets(csvFile, logger), 'AppAdmin');
          case FileType.company:
            await client.importCompanies(csvToCompanies(csvFile));
          case FileType.user:
            await client.importUsers(csvToUsers(csvFile));
          case FileType.website:
            await client.importWebsite(csvToWebsite(csvFile));
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
  } on DioException catch (e) {
    logger.e("Importing filetype: ${fileType.name} Error: ${getDioError(e)}");
  }
}
