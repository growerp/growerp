#!/usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:growerp_models_new/growerp_models_new.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../build_dio_client.dart';
import '../file_type_model.dart';
import '../get_dio_error.dart';
import '../get_file_type.dart';
import '../get_files.dart';

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

Future<void> main(List<String> args) async {
  String growerpPath = '$HOME/growerpTest';
  String validCommands = "valid commands are:'install | import'";
  String branch = 'master';
  String inputFile = '';
  Hive.init('growerp');
  var box = await Hive.openBox('growerp');

  if (args.isEmpty) {
    print('Please enter a GrowERP command? $validCommands');
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
        default:
          modifiedArgs.add(args[i]);
      }
    }

    // commands
    switch (modifiedArgs[0].toLowerCase()) {
      case 'install':
        if (exists(growerpPath)) {
          if (!exists('$growerpPath/flutter')) {
            print("growerp directory exist but is not a GrowERP repository!");
            exit(1);
          }
          print("growerp directory already exist, will upgrade it");
          run('git stash', workingDirectory: '$growerpPath');
          run('git pull', workingDirectory: '$growerpPath');
          run('git stash pop', workingDirectory: '$growerpPath');
        } else {
          'git clone -b $branch https://github.com/growerp/moqui-framework.git '
              '$growerpPath';
        }
        run('gnome-terminal -- bash -c "cd $growerpPath/chat && ./gradlew apprun"');
        if (!exists('$growerpPath/moqui/moqui.war')) {
          run('./gradlew build', workingDirectory: '$growerpPath/moqui');
          run('java -jar moqui.war load types=seed,seed-initial,install',
              workingDirectory: '$growerpPath/moqui');
        }
        run('java -jar moqui.war', workingDirectory: '$growerpPath/moqui');
        run('gnome-terminal -- bash -c "cd $growerpPath/flutter"');
        if (branch != 'master' &&
            !exists(
                "$growerpPath/flutter/packages/admin/pubspec_overrides.yaml")) {
          run("dart pub global activate melos");
          String path = "$PATH";
          if (!path.contains("$HOME/.pub-cache/bin")) {
            print("To run melos add $HOME/.pub-cache/bin to your path");
            run("PATH=$HOME/.pub-cache/bin");
          }
          run('melos bootstrap');
        }
        if (branch != 'master' &&
            !exists(
                "$growerpPath/flutter/packages/growerp_core/lib/src/models/account_class_model.freezed.dart")) {
          run("melos build_all --no-select");
        }
        if (branch != 'master' &&
            !exists(
                "$growerpPath/flutter/packages/growerp_core/lib/src/l10n/generated")) {
          run("melos l10n --no-select");
        }
        break;
      case 'import':
        var logger = Logger(filter: MyFilter());
        List<String> files = getFiles(inputFile);
        if (files.isEmpty) exit(1);

        // talk to backend
        final dio =
            buildDioClient('http://localhost:8080/'); // Provide a dio instance
        final client = RestClient(await dio);
        String username = 'test200@example.com';
        String password = 'qqqqqq9!';
        try {
          // register
//          await client.register(username, 'q$username', password, 'Hans',
//              'Jansen', 'test company', 'USD', 'AppAdmin', false);
          // login to get apiKey
//          Authenticate authenticate =
//              await client.login(username, password, 'AppAdmin');
//          logger.i("auth: ${authenticate}");
          // save key
//          box.put('apiKey', authenticate.apiKey);
          // import
          for (String file in files) {
            FileType fileType = getFileType(file);
            String csvFile = File(file).readAsStringSync();
            var json = [];
            switch (fileType) {
              case FileType.glAccount:
                json = GlAccountCsvToJson(csvFile);
                break;
              default:
                print("FileType ${fileType.name} not implemented yet");
                exit(1);
            }
            var result = await client.import({
              'entities': {'${fileType.name}s': json}
            });
            logger.i("file: $file result: $result");
          }
        } on DioException catch (e) {
          logger.e(getDioError(e));
        }
    }
  }
}
