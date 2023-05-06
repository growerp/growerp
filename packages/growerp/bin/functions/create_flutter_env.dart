import 'dart:io';
import 'dart:typed_data';

import 'package:dcli/dcli.dart';

import '../models/globals.dart';
import 'functions.dart';

void createFlutterEnv() {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (!exists('$growerpPath/flutterDevelopment')) {
    logger.i('creating flutter release...');
    // growerp
    run('git clone https://github.com/growerp/growerp.git '
        '$growerpPath/flutterRelease');
    logger.i('copy release to development, and switch to branch development');
    run('cp -r $growerpPath/flutterRelease '
        '$growerpPath/flutterDevelopment');
    run('git checkout development',
        workingDirectory: '$growerpPath/flutterDevelopment');
  } else {
    logger
      ..i('from git updating local installation at $growerpPath/flutter*')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/flutterDevelopment');
    run('git pull', workingDirectory: '$growerpPath/flutterDevelopment');
    run('git stash', workingDirectory: '$growerpPath/flutterRelease');
    run('git pull', workingDirectory: '$growerpPath/flutterRelease');
  }
  logger.i('building packages in development...');
  getPackageList().forEach((package) {
    logger.i('building package: ${package.name}');
    run('flutter pub get', workingDirectory: package.fileLocation);
    if (package.buildRunner) {
      // has buildrunner installed?
      run('flutter pub run build_runner build --delete-conflicting-outputs',
          workingDirectory: package.fileLocation);
    }
  });
  // change config to use growerp test backend
  if (!exists('$growerpPath/moquiDevelopment')) {
    updateAppSettings();
  }
  // start admin flutter in new window
  run('flutter pub get',
      workingDirectory: '$growerpPath/flutterDevelopment/packages/admin');
  if (Platform.isLinux) {
    logger.i('Starting flutter in different window....');
    run('gnome-terminal -- bash -c "cd $growerpPath/flutterDevelopment/packages/admin && flutter run"');
  }
}
