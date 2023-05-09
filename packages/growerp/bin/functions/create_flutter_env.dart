import 'dart:io';
import 'package:dcli/dcli.dart';

import '../models/models.dart';
import 'functions.dart';

void createFlutterEnv({Environment? env, bool start = false}) {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (env == null || env == Environment.development) {
    getFlutterFiles('flutterDevelopment');
    // start admin flutter in new window
    run('flutter pub get',
        workingDirectory: '$growerpPath/flutterDevelopment/packages/admin');
    if (start && Platform.isLinux) {
      logger.i('Starting flutter in different window....');
      run('gnome-terminal -- bash -c "cd $growerpPath/flutterDevelopment/packages/admin && flutter run"');
    }
  }
  if (env == null || env == Environment.release) {
    getFlutterFiles('flutterRelease');
  }
}

void getFlutterFiles(String targetDir) {
  if (!exists('$growerpPath/$targetDir')) {
    logger.i('creating $targetDir...');

    if (targetDir == 'flutterDevelopment' &&
            exists('$growerpPath/flutterRelease') ||
        targetDir == 'flutterRelease' &&
            exists('$growerpPath/flutterDevelopment')) {
      if (targetDir == 'development') {
        run("cp '$growerpPath/flutterRelease' '$growerpPath/flutterDevelopment'");
      } else {
        run("cp '$growerpPath/flutterDevelopment' '$growerpPath/flutterRelease'");
      }
      run('git clean -f', workingDirectory: '$growerpPath/$targetDir');
      run('git stash', workingDirectory: '$growerpPath/$targetDir');
      if (targetDir == 'flutterDevelopment') {
        run('git checkout development',
            workingDirectory:
                '$growerpPath/$targetDir/runtime/component/growerp');
      } else {
        run('git checkout master',
            workingDirectory:
                '$growerpPath/$targetDir/runtime/component/growerp');
      }
    } else {
      run('git clone https://github.com/growerp/growerp.git '
          '$growerpPath/$targetDir');
    }
  } else {
    logger
      ..i('from git updating local installation at $growerpPath/flutter*')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/$targetDir');
    run('git pull', workingDirectory: '$growerpPath/$targetDir');
  }
  // build development system
  if (targetDir == 'flutterDevelopment') {
    logger.i('building packages in development...');
    final packages = getPackageList();
    if (packages.isEmpty) {
      logger.e('No packages could be build, pub.dev limit reached? '
          'try later again');
      return;
    }
    for (final package in packages) {
      logger.i('building package: ${package.name}');
      run('flutter pub get', workingDirectory: package.fileLocation);
      if (package.buildRunner) {
        // has buildrunner installed?
        run('flutter pub run build_runner build --delete-conflicting-outputs',
            workingDirectory: package.fileLocation);
      }
    }
    // change config to use growerp test backend
    if (!exists('$growerpPath/moquiDevelopment')) {
      updateAppSettings();
    }
  }
}
