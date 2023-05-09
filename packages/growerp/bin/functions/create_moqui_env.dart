import 'dart:io';

import 'package:dcli/dcli.dart';

import '../models/models.dart';

void createMoquiEnv(
    {Environment? env, bool start = false, bool noBuild = false}) {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (env == null || env == Environment.development) {
    getMoquiFiles('moquiDevelopment', noBuild);
    if (start && Platform.isLinux) {
      logger.i('Starting Moqui in different window....');
      run('gnome-terminal -- bash -c "cd $growerpPath/moquiDevelopment && java -jar moqui.war"');
    }
  }
  if (env == null || env == Environment.release) {
    getMoquiFiles('moquiRelease', noBuild);
  }
}

void getMoquiFiles(String targetDir, bool noBuild) {
  if (!exists('$growerpPath/$targetDir')) {
    logger.i('creating moqui $targetDir part...');

    if (targetDir == 'moquiDevelopment' &&
            exists('$growerpPath/moquiRelease') ||
        targetDir == 'moquiRelease' &&
            exists('$growerpPath/moquiDevelopment')) {
      if (targetDir == 'development') {
        run("cp '$growerpPath/moquiRelease' '$growerpPath/moquiDevelopment'");
      } else {
        run("cp '$growerpPath/moquiDevelopment' '$growerpPath/moquiRelease'");
      }
      run('git clean -f', workingDirectory: '$growerpPath/$targetDir');
      run('git stash', workingDirectory: '$growerpPath/$targetDir');
      if (targetDir == 'moquiDevelopment') {
        run('git checkout development',
            workingDirectory:
                '$growerpPath/$targetDir/runtime/component/growerp');
      } else {
        run('git checkout master',
            workingDirectory:
                '$growerpPath/$targetDir/runtime/component/growerp');
      }
      run('./gradlew cleanall', workingDirectory: '$growerpPath/$targetDir');
    } else {
      run('git clone -b growerp https://github.com/growerp/moqui-framework.git '
          '$growerpPath/$targetDir');
      run('git clone https://github.com/growerp/moqui-runtime '
          '$growerpPath/$targetDir/runtime');
      run('git clone https://github.com/growerp/growerp-moqui.git '
          '$growerpPath/$targetDir/runtime/component/growerp');
      run('git clone -b growerp https://github.com/growerp/PopRestStore.git '
          '$growerpPath/$targetDir/runtime/component/PopRestStore');
      run('git clone -b growerp https://github.com/growerp/mantle-udm.git'
          ' -b growerp $growerpPath/$targetDir/runtime/component/mantle-udm');
      run('git clone -b growerp https://github.com/growerp/mantle-usl.git '
          '$growerpPath/$targetDir/runtime/component/mantle-usl');
      run('git clone https://github.com/growerp/mantle-stripe.git '
          '$growerpPath/$targetDir/runtime/component/mantle-stripe');
      run('git clone https://github.com/growerp/moqui-fop.git '
          '$growerpPath/$targetDir/runtime/component/moqui-fop');
      run('./gradlew downloadElasticSearch',
          workingDirectory: '$growerpPath/$targetDir');
    }
  } else {
    logger
      ..i('updating local installation at $growerpPath/moquiDevelopment')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/$targetDir');
    run('./gradlew gitp', workingDirectory: '$growerpPath/$targetDir');
    run('./gradlew cleanall', workingDirectory: '$growerpPath/$targetDir');
  }
  if (!noBuild) {
    logger.i('build Moqui backend');
    run('./gradlew build', workingDirectory: '$growerpPath/$targetDir');
    run('java -jar moqui.war load types=seed,seed-initial,install',
        workingDirectory: '$growerpPath/$targetDir');
  }
}
