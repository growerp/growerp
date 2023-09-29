#!/usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models_new/growerp_models_new.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../dio_client.dart';
import '../get_dio_error.dart';

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
  if (args.isEmpty) {
    print('Please enter a GrowERP command? $validCommands');
  } else {
    final modifiedArgs = <String>[];
    for (final arg in args) {
      switch (arg) {
        case '-dev':
          branch = 'development';
          break;
        default:
          modifiedArgs.add(arg);
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
        final dio =
            buildDioClient('http://localhost:8080/'); // Provide a dio instance
        dio.options.headers["Demo-Header"] =
            "demo header"; // config your dio headers globally
        final client = RestClient(dio);
        String username = 'test104@example.com';
        String password = 'qqqqqq9!';
        Authenticate result = Authenticate();
        try {
          // register
          result = await client.register(username, 'q$username', password,
              'Hans', 'Jansen', 'test company', 'USD', 'AppAdmin', false);
          logger.i("Result: owner: ${result.ownerPartyId} "
              "user: ${result.user} company: ${result.company}");
          // login to get apiKey
          result = await client.login(username, password, 'AppAdmin');
          logger.i(result.apiKey);
        } on DioException catch (e) {
          logger.e(getDioError(e));
        }

      /*       if (modifiedArgs[0].isEmpty || !exists(modifiedArgs[0])) {
          print("Missing or not found csv filename");
          exit(1);
        }
        var config = File(modifiedArgs[0]);
        String csv = await config.readAsString();
        final result = fast_csv.parse(csv);
        for (final row in result) {
          print('$row[0] $row[1] $row[2] $row[3] $row[4] ');
        }
*/
    }
  }
}
