import 'dart:io';

import 'package:dcli/dcli.dart';

import '../models/globals.dart';

void createMopquiEnv() {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (!exists('$growerpPath/moquiDevelopment')) {
    logger.i('creating moqui part...');
    run('git clone -b growerp https://github.com/growerp/moqui-framework.git '
        '$growerpPath/moquiRelease');
    run('git clone https://github.com/growerp/moqui-runtime '
        '$growerpPath/moquiRelease/runtime');
    run('git clone https://github.com/growerp/growerp-moqui.git '
        '$growerpPath/moquiRelease/runtime/component/growerp');
    run('git clone -b growerp https://github.com/growerp/PopRestStore.git '
        '$growerpPath/moquiRelease/runtime/component/PopRestStore');
    run('git clone -b growerp https://github.com/growerp/mantle-udm.git'
        ' -b growerp $growerpPath/moquiRelease/runtime/component/mantle-udm');
    run('git clone -b growerp https://github.com/growerp/mantle-usl.git '
        '$growerpPath/moquiRelease/runtime/component/mantle-usl');
    run('git clone https://github.com/growerp/mantle-stripe.git '
        '$growerpPath/moquiRelease/runtime/component/mantle-stripe');
    run('git clone https://github.com/growerp/moqui-fop.git '
        '$growerpPath/moquiRelease/runtime/component/moqui-fop');
    run('./gradlew downloadElasticSearch',
        workingDirectory: '$growerpPath/moquiRelease');
    run('./gradlew build', workingDirectory: '$growerpPath/moquiRelease');
    run('java -jar moqui.war load types=seed,seed-initial,install',
        workingDirectory: '$growerpPath/moquiRelease');
    logger.i('creating moqui development...');
    // moqui development copy from release and switch branch
    run('cp -r $growerpPath/moquiRelease $growerpPath/moquiDevelopment');
    run('git checkout development',
        workingDirectory:
            '$growerpPath/moquiRelease/runtime/component/growerp');
    run('./gradlew build', workingDirectory: '$growerpPath/moquiDevelopment');
    run('java -jar moqui.war load types=seed,seed-initial,install',
        workingDirectory: '$growerpPath/moquiDevelopment');
  } else {
    logger
      ..i('updating local installation at $growerpPath/flutter*')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/moquiDevelopment');
    run('./gradlew gitp', workingDirectory: '$growerpPath/moquiDevelopment');
    run('git stash', workingDirectory: '$growerpPath/moquiRelease');
    run('./gradlew gitp', workingDirectory: '$growerpPath/moquiRelease');
  }
  if (Platform.isLinux) {
    logger.i('Starting Moqui and chat in different window....');
    run('gnome-terminal -- bash -c "cd $growerpPath/moquiDevelopment && java -jar moqui.war"');
    run('gnome-terminal -- bash -c "cd $growerpPath/chatDevelopment && ./gradlew apprun"');
  }
}
