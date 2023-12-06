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

import '../file_type_model.dart';
import '../get_file_type.dart';
import '../get_files.dart';
import '../logger.dart';

Future<void> main(List<String> args) async {
  String growerpPath = '$HOME/growerp';
  String validCommands = "valid commands are:'install | import | export'";
  String branch = 'master';
  String inputFile = '';
  String username = '';
  String password = '';
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
          break;
        case '-f':
          overrideFileType = getFileType(args[++i]);
          break;
        default:
          modifiedArgs.add(args[i]);
      }
    }
    //logger.i(
    //    "Growerp exec cmd: ${modifiedArgs[0].toLowerCase()} u: $username p: $password -branch: $branch");

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
              demoData: true,
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
          print("======777===========$result");
          authenticate =
              Authenticate.fromJson({'authenticate': jsonDecode(result)});
        }
      }
    }

    // commands
    switch (modifiedArgs[0].toLowerCase()) {
      case 'install':
        logger.i(
            'installing GrowERP: chat,backend and starting the flutter admin app');
        if (exists(growerpPath)) {
          if (!exists('$growerpPath/flutter')) {
            logger.e(
                "$growerpPath directory exist but is not a GrowERP repository!");
            exit(1);
          }
          logger.i("growerp directory already exist, will upgrade it");
          run('git stash', workingDirectory: '$growerpPath');
          run('git pull', workingDirectory: '$growerpPath');
          run('git stash pop', workingDirectory: '$growerpPath');
        } else {
          run('git clone -b $branch https://github.com/growerp/growerp.git $growerpPath',
              workingDirectory: '$HOME');
          run('./gradlew downloadel', workingDirectory: '$growerpPath/moqui');
        }
        run('gnome-terminal -- bash -c "cd $growerpPath/chat && ./gradlew apprun"');
        if (!exists('$growerpPath/moqui/moqui.war')) {
          run('./gradlew build', workingDirectory: '$growerpPath/moqui');
          run('java -jar moqui.war load types=seed,seed-initial,install',
              workingDirectory: '$growerpPath/moqui');
        }
        run('gnome-terminal -- bash -c "cd $growerpPath/moqui && java -jar moqui.war"');
        if (branch != 'master') {
          if (!exists(
              "$growerpPath/flutter/packages/admin/pubspec_overrides.yaml")) {
            run('dart pub global activate melos',
                workingDirectory: '$growerpPath/flutter');
            String path = "$PATH";
            if (!path.contains("$HOME/.pub-cache/bin")) {
              run("PATH=$HOME/.pub-cache/bin");
            }
            run('melos bootstrap', workingDirectory: '$growerpPath/flutter');
          }
          if (!exists(
              "$growerpPath/flutter/packages/growerp_core/lib/src/models/account_class_model.freezed.dart")) {
            run('melos build_all --no-select',
                workingDirectory: '$growerpPath/flutter');
          }
          if (!exists(
              "$growerpPath/flutter/packages/growerp_core/lib/src/l10n/generated")) {
            run('melos l10n --no-select',
                workingDirectory: '$growerpPath/flutter');
          }
        }
        logger.i("Install successfull, now starting the admin app with chrome");
        run('flutter run',
            workingDirectory: '$growerpPath/flutter/packages/admin');
        break;
      case 'import':
        List<String> files =
            getFiles(inputFile, overrrideFileType: overrideFileType);
        if (files.isEmpty) {
          logger.e("no files found to process, use the -i directive?");
          exit(1);
        }
        // talk to backend
        final client = RestClient(
            await buildDioClient(null, timeout: Duration(seconds: 20)));
        try {
          await login(client);
          // import
          for (String file in files) {
            logger.i("Importing file: $file with admin user: "
                "${authenticate.user?.email}");
            FileType fileType = getFileType(file);
            String csvFile = File(file).readAsStringSync();
            switch (fileType) {
              case FileType.glAccount:
                await client.importGlAccounts(CsvToGlAccounts(csvFile));
                break;
              case FileType.product:
                await client.importProducts(CsvToProducts(csvFile), 'AppAdmin');
                break;
              case FileType.category:
                await client.importCategories(CsvToCategories(csvFile));
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

              default:
                logger.e("FileType ${fileType.name} not implemented yet");
                exit(1);
            }
          }
        } on DioException catch (e) {
          logger.e(getDioError(e));
        }
        break;
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
        final client = RestClient(await buildDioClient(null));
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
          logger.e(getDioError(e));
        }
        break;
      default:
        logger.e("${modifiedArgs[0]} not a valid subcommand");
    }
  }
}
