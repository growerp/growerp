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
      ..i('updating local installation at $growerpPath/flutter*')
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
    run('flutter pub run build_runner build --delete-conflicting-outputs',
        workingDirectory: package.fileLocation);
  });
  // growerp package rel/dev
  logger.i('build package growerp both dev and release');
  run('flutter pub get',
      workingDirectory: '$growerpPath/flutterDevelopment/packages/growerp');
  run('flutter pub run build_runner build --delete-conflicting-outputs',
      workingDirectory: '$growerpPath/flutterDevelopment/packages/growerp');
  run('flutter pub get',
      workingDirectory: '$growerpPath/flutterRelease/packages/growerp');
  run('flutter pub run build_runner build --delete-conflicting-outputs',
      workingDirectory: '$growerpPath/flutterRelease/packages/growerp');
  // change config to use growerp test backend
  final configFile = File(
      '$growerpPath/flutterDevelopment/packages/admin/assets/cfg/app_settings.json');
  final config = configFile.readAsLinesSync().toList();
  var newLine = '';
  final write = configFile.openWrite();
  for (final line in config) {
    newLine = line;
    if (line.contains('databaseUrlDebug')) {
      newLine = '"databaseUrlDebug": "https://test.growerp.org",\n';
    }
    if (line.contains('chatUrlDebug')) {
      newLine = '"chatUrlDebug": "wss://chat.growerp.org",\n';
    }
    write.write('$newLine\n');
  }
  write.close();
  // start flutter in new window
  if (Platform.isLinux) {
    logger.i('Starting flutter in different window....');
    run('gnome-terminal -- bash -c "cd $growerpPath/flutterDevelopment/packages/admin && flutter run"');
  }
}
