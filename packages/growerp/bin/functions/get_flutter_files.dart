import 'dart:io';

import 'package:dcli/dcli.dart';

import '../models/models.dart';
import 'functions.dart';

/// get flutter files from the git repository and create a development and/or
/// release version of the system.
void getFlutterFiles(String targetDir) {
  if (!exists('$growerpPath/$targetDir')) {
    logger.i('creating $targetDir...');
    // get from git
    run('git clone https://github.com/growerp/growerp.git '
        '$growerpPath/$targetDir');
    if (targetDir == 'flutterDevelopment') {
      run('git checkout development',
          workingDirectory: '$growerpPath/$targetDir');
    }
  } else {
    logger
      ..i('from git updating local installation at $growerpPath/flutter*')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/$targetDir');
    run('git pull', workingDirectory: '$growerpPath/$targetDir');
  }
}
