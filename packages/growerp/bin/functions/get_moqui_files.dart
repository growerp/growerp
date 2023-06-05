import 'dart:io';

import 'package:dcli/dcli.dart';

import '../models/models.dart';

/// get moqui files from git repository and optionally build.
void getMoquiFiles(String targetDir, {bool build = false}) {
  if (!exists('$growerpPath/$targetDir')) {
    logger.i('creating moqui $targetDir part...');
    'git clone -b growerp https://github.com/growerp/moqui-framework.git '
        '$growerpPath/$targetDir';
    'git clone https://github.com/growerp/moqui-runtime '
        '$growerpPath/$targetDir/runtime';
    'git clone https://github.com/growerp/growerp-moqui.git '
        '$growerpPath/$targetDir/runtime/component/growerp';
    'git clone -b growerp https://github.com/growerp/PopRestStore.git '
        '$growerpPath/$targetDir/runtime/component/PopRestStore';
    'git clone -b growerp https://github.com/growerp/mantle-udm.git'
        ' -b growerp $growerpPath/$targetDir/runtime/component/mantle-udm';
    'git clone -b growerp https://github.com/growerp/mantle-usl.git '
        '$growerpPath/$targetDir/runtime/component/mantle-usl';
    'git clone https://github.com/growerp/mantle-stripe.git '
        '$growerpPath/$targetDir/runtime/component/mantle-stripe';
    'git clone https://github.com/growerp/moqui-fop.git '
        '$growerpPath/$targetDir/runtime/component/moqui-fop';
    run('./gradlew downloadElasticSearch',
        workingDirectory: '$growerpPath/$targetDir');
    // modify branches for development
    if (targetDir == 'moquiDevelopment') {
      run('git checkout development',
          workingDirectory:
              '$growerpPath/$targetDir/runtime/component/growerp');
    }
    // apply patches when not currently using growerp branch
    var result = start('git branch',
        workingDirectory:
            '$growerpPath/$targetDir/runtime/component/mantle-udm');
    if (!result.toList().contains('growerp')) {
      var componentDirectory =
          '$growerpPath/$targetDir/runtime/component/growerp/patches/mantle-udm';
      // need to patch if pactches found
      var files = Directory('componentDirectory')
          .listSync(recursive: false, followLinks: false)
          .toList();
      for (var file in files) {
        if (run('git am $file', workingDirectory: componentDirectory) != 0)
          exit(3);
      }
    }
  } else {
    logger
      ..i('updating local installation at $growerpPath/moquiDevelopment')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/$targetDir');
    run('./gradlew gitp', workingDirectory: '$growerpPath/$targetDir');
    run('./gradlew cleanall', workingDirectory: '$growerpPath/$targetDir');
  }
  if (build) {
    logger.i('build Moqui backend');
    run('./gradlew build', workingDirectory: '$growerpPath/$targetDir');
    run('java -jar moqui.war load types=seed,seed-initial,install',
        workingDirectory: '$growerpPath/$targetDir');
  }
}
