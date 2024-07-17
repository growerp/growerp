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
      "valid commands are:'install | import | export | finalize'";
  String? backendUrl;
  String outputDirectory = 'growerpCsv';
  String branch = 'master';
  String inputFile = '';
  String username = '';
  String password = '';
  int timeout = 600; //in seconds
  FileType overrideFileType = FileType.unknown;
  Hive.init('growerpDB');
  var logger = Logger(filter: MyFilter());

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

    // commands
    if (modifiedArgs.isEmpty) {
      logger.e("No growerp subcommand found.");
    }
    switch (modifiedArgs[0].toLowerCase()) {
      case 'install':
        install(growerpPath, branch);
        break;
      case 'import':
        import(inputFile, backendUrl, username, password);
        break;
      case 'finalize':
        final client = RestClient(await buildDioClient(backendUrl,
            timeout: Duration(seconds: timeout), miniLog: true));
        await login(client, username, password);
        client.finalizeImport();
        break;
      case 'export':
        if (modifiedArgs.length > 1) {
          try {
            // ignore: unused_local_variable
            FileType fileType = FileType.values.byName(modifiedArgs[1]);
          } catch (e) {
            logger.e(
                "invalid file type: ${modifiedArgs[1]}, valid types: ${FileType.values.join().replaceAll('FileType.', ',').replaceAll(',unknown', '')}");
            exit(1);
          }
        }
        export(backendUrl, outputDirectory, username, password);
        break;
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
