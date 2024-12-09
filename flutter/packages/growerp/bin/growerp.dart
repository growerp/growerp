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

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';

import 'package:growerp/src/src.dart';

Future<void> main(List<String> args) async {
  String growerpPath = '$HOME/growerp';
  String validCommands =
      "valid commands are:'help | install | import | export | finalize'";
  String? backendUrl;
  String outputDirectory = 'growerpCsv';
  String branch = 'master';
  String inputFile = '';
  String username = '';
  String password = '';
  String companyName = '';
  String currencyId = '';
  String fiscalYear = '';
  int timeout = 600; //in seconds
  FileType startFileType = FileType.unknown;
  FileType stopFileType = FileType.unknown;
  String startFileName = '';
  Hive.init('growerpDB');
  var logger = Logger(filter: MyFilter());
  var fileTypeList = FileType.values
      .join()
      .replaceAll('FileType.', ',')
      .replaceAll(',unknown', '');

  if (args.isEmpty) {
    logger.e('Please enter a GrowERP command? $validCommands');
  } else {
    final modifiedArgs = <String>[];
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '-dev':
          branch = 'development';
        case '-url':
          backendUrl = args[++i];
        case '-i':
          inputFile = args[++i];
        case '-u':
          username = args[++i];
        case '-n':
          companyName = args[++i];
        case '-c':
          currencyId = args[++i];
        case '-p':
          password = args[++i];
        case '-o':
          outputDirectory = args[++i];
        case '-t':
          timeout = int.parse(args[++i]);
        case '-ft':
          i++;
          startFileType = FileType.values.firstWhere((e) => e.name == args[i],
              orElse: () => FileType.unknown);
          if (startFileType == FileType.unknown) {
            logger.e(
                "Start Filetype: ${args[i]}  not recognized, existing filetypes $fileTypeList");
            exit(1);
          }
        case '-sft':
          i++;
          stopFileType = FileType.values.firstWhere((e) => e.name == args[i],
              orElse: () => FileType.unknown);
          if (stopFileType == FileType.unknown) {
            logger.e(
                "Stop Filetype: ${args[i]}  not recognized, existing filetypes $fileTypeList");
            exit(1);
          }
        case '-fn':
          startFileName = args[++i];
        case '-y':
          fiscalYear = args[++i];
        default:
          modifiedArgs.add(args[i]);
      }
    }
    logger.i("Growerp command: ${modifiedArgs[0].toLowerCase()} i: $inputFile "
        "u: $username p: $password -branch: $branch -ft ${startFileType.name} "
        "-fn $startFileName -sft ${stopFileType.name} -n $companyName -y $fiscalYear");

    // commands
    if (modifiedArgs.isEmpty) {
      logger.e("No growerp subcommand found.");
    }
    switch (modifiedArgs[0].toLowerCase()) {
      case 'help':
        // ignore: avoid_print
        print("Help for the growerp command\n"
            " -- install:\n "
            "     will install the complete system: frontend, backend and chat\n"
            "     and will start the backend and chat in the background.\n"
            "     The install directory will be $HOME/growerp\n"
            "     The admin frontend can now be started with the 'flutter run' command\n"
            "       in the directory growerp/flutter/packages/admin\n"
            " -- import:\n "
            "     will import standard csv files into a local or remote system\n"
            "     these standard csv files can be created by the conversion framework\n"
            "     in the command convert_to_csv\n"
            "     A new company and admin will be created in the process\n"
            "     Parameters:\n"
            "     -i    input directory which contains the csv files and images\n"
            "     -u    user email address to for logging in.\n"
            "     -p    password for logging in.\n"
            "     -url  The backend url or empty for localhost\n"
            "     -n    The new company name\n"
            "     -c    The currency id to be used, example: USD,EUR\n"
            "     -ft   resume from this filetype\n"
            "     -fn   resume from this filename\n"
            "     -sft  stop just before this filetype\n"
            " -- export: (under development)\n "
            "     Will export all company related information in csv files\n"
            "     -u    user email address to for logging in.\n"
            "     -p    password for logging in.\n"
            "     -o    output directory name\n"
            "     -f    just this filetype\n"
            " -- finalize:\n "
            "     wil finalize the import process by completing finished \n"
            "     documents and accounting time periods.\n"
            "     -u    user email address to for logging in.\n"
            "     -p    password for logging in.\n"
            "     -Y    YYYY  close a specific fiscal year, when missing close all except current year\n");
        exit(1);
      case 'install':
        install(growerpPath, branch);
      case 'import':
        import(
            inputFile, backendUrl, username, password, companyName, currencyId,
            startFileType: startFileType,
            startFileName: startFileName,
            stopFileType: stopFileType);
      case 'finalize':
        final client = RestClient(await buildDioClient(backendUrl,
            timeout: Duration(seconds: timeout), miniLog: true));
        await login(client, username, password,
            companyName: companyName, currencyId: currencyId);

        Map<String, int> parts = {
          'closePeriod': 1,
          'approveInvoices': 10000,
          'completePayments': 10000,
          'completeInvoicesOrders': 10000,
          'receiveShipments': 10000,
          'sendShipments': 10000,
        };
        int start = 0, limitOut; //, count = 2;
        Map<String, dynamic> result = {};
        try {
          parts.forEach((part, limit) async {
            logger.i("processing finalize part: $part");
            start = 0;
            do {
              print("start: $start limit: $limit");
              result = await client.finalizeImport(
                  start: start, limit: limit, part: part);
              print("result part: $part ${result['limitOut']}");
              limitOut = int.parse(result['limitOut']);
              start += limitOut;
              print("===end of while: $limitOut != -1");
            } while (limitOut != -1); // && --count != 0);
          });
        } catch (e) {
          logger.e("====error: $e");
          exit;
        }

      case 'export':
        export(backendUrl, outputDirectory, username, password);
      case 'report':
        // (hansbak): create a data (conversion) report
        // how many open documents order,invoices, payments  value
        // how many orders with no invoices
        // how many invoices with no ledger tranactions
        // etc, etc..
        logger.e("${modifiedArgs[0]} report not implemented yet");
      default:
        logger.e("${modifiedArgs[0]} not a valid subcommand");
    }
  }
}
