import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';

import '../src.dart';

Future<void> export(String? backendUrl, String outputDirectory, String username,
    String password) async {
  var logger = Logger(filter: MyFilter());
  int timeout = 600; //in seconds

  FileType fileType = FileType.unknown;

  final client = RestClient(
      await buildDioClient(backendUrl, timeout: Duration(seconds: timeout)));
  try {
    if (isDirectory(outputDirectory)) {
      logger.e(
          "output directory $outputDirectory already exists, do not overwrite");
      exit(1);
    }

    createDir(outputDirectory);
    if (username.isNotEmpty && password.isNotEmpty) {
      await login(client, username, password);
    }
    String csvContent = '';
    // export glAccount
    if (fileType == FileType.unknown || fileType == FileType.glAccount) {
      GlAccounts result = await client.getGlAccount(limit: 999);
      csvContent = csvFromGlAccounts(result.glAccounts);
      final file1 = File("$outputDirectory/${FileType.glAccount.name}.csv");
      file1.writeAsStringSync(csvContent);
    }
    // export company
    if (fileType == FileType.unknown || fileType == FileType.company) {
      Companies result = await client.getCompany(limit: 999);
      csvContent = csvFromCompanies(result.companies);
      final file2 = File("$outputDirectory/${FileType.company.name}.csv");
      file2.writeAsStringSync(csvContent);
    }
    // export users
    if (fileType == FileType.unknown || fileType == FileType.user) {
      Users result = await client.getUsers('999');
      csvContent = csvFromUsers(result.users);
      final file3 = File("$outputDirectory/${FileType.user.name}.csv");
      file3.writeAsStringSync(csvContent);
    }
    // export products
    if (fileType == FileType.unknown || fileType == FileType.product) {
      Products result = await client.getProducts(limit: 999);
      csvContent = csvFromProducts(result.products);
      final file4 = File("$outputDirectory/${FileType.product.name}.csv");
      file4.writeAsStringSync(csvContent);
    } // export categories
    if (fileType == FileType.unknown || fileType == FileType.category) {
      fileType = FileType.category;
      Categories result = await client.getCategories(limit: 999);
      csvContent = csvFromCategories(result.categories);
      final file5 = File("$outputDirectory/${FileType.category.name}.csv");
      file5.writeAsStringSync(csvContent);
    }
    // export website
    if (fileType == FileType.unknown || fileType == FileType.website) {
      fileType = FileType.website;
      Website result = await client.exportWebsite();
      csvContent = csvFromWebsite(result);
      final file6 = File("$outputDirectory/${FileType.website.name}.csv");
      file6.writeAsStringSync(csvContent);
    }
  } on DioException catch (e) {
    logger.e("Exporting filetype: $fileType Error: ${getDioError(e)}");
  }
}
