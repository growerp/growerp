import 'dart:io';
import 'package:dcli/dcli.dart';

import '../src.dart';

install(String growerpPath, String branch) {
  logger
      .i('installing GrowERP: chat,backend and starting the flutter admin app');
  if (exists(growerpPath)) {
    if (!exists('$growerpPath/flutter')) {
      logger.e("$growerpPath directory exist but is not a GrowERP repository!");
      exit(1);
    }
    logger.i("growerp directory already exist, will upgrade it");
    // only stash and pop if changes present
    var lines = '';
    'git status'.start(
        workingDirectory: growerpPath,
        progress: Progress((line) => lines += line));
    if (!lines.contains('working tree clean')) {
      run('git stash', workingDirectory: growerpPath);
    }
    run('git pull', workingDirectory: growerpPath);
    if (!lines.contains('working tree clean')) {
      run('git stash pop', workingDirectory: growerpPath);
    }
  } else {
    run('git clone -b $branch https://github.com/growerp/growerp.git $growerpPath',
        workingDirectory: HOME);
  }
  logger.i('Start backend in separate window...');
  run('gnome-terminal -- bash -c "cd $growerpPath/moqui && java -jar moqui.war"');
  if (!exists("$growerpPath/flutter/packages/admin/pubspec_overrides.yaml")) {
    logger.i('activate melos package to build frontend...');
    run('dart pub global activate melos',
        workingDirectory: '$growerpPath/flutter');
    String path = "$PATH";
    if (!path.contains("$HOME/.pub-cache/bin")) {
      run("PATH=$HOME/.pub-cache/bin");
    }
    run('melos bootstrap', workingDirectory: '$growerpPath/flutter');
  }
  if (!exists(
      "$growerpPath/flutter/packages/growerp_models/lib/src/models/account_class_model.freezed.dart")) {
    logger.i('build flutter frontend with freezed....');
    run('melos build --no-select', workingDirectory: '$growerpPath/flutter');
  }
  if (!exists(
      "$growerpPath/flutter/packages/growerp_core/lib/src/l10n/generated")) {
    logger.i('Create language translation files...');
    run('melos l10n --no-select', workingDirectory: '$growerpPath/flutter');
  }
  logger.i("Install successfull, now starting the admin app with chrome\n"
      " You can create company and login, parameters are provided...");
  run('flutter run -d chrome',
      workingDirectory: '$growerpPath/flutter/packages/admin');
}
