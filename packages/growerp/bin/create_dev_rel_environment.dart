#! /usr/bin/env dcli

// ignore_for_file: avoid_dynamic_calls
import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

import 'functions/functions.dart';
import 'models/globals.dart';

Logger logger = Logger(
  printer: PrettyPrinter(),
);

void main(List<String> args) {
  logger.i('creating a release and development environment\n'
      'all files are in the home/growerp directory\n'
      'flutter/development & flutter/release: flutter\n'
      'moqui/development moqui/release moqui backend\n'
      'chat/development chat/release chat server\n'
      'creating growerp...');

  try {
    if (!exists(growerpPath)) {
      logger.i('creating flutter part...');
      // growerp
      run('mkdir $growerpPath');
      run('git clone https://github.com/growerp/growerp.git '
          '$growerpPath/flutterRelease');
      run('cp -r $growerpPath/flutterRelease '
          '$growerpPath/flutterDevelopment');
      run('git checkout development',
          workingDirectory: '$growerpPath/flutterDevelopment');
      logger.i('\n\ncreating moqui release...');
      // moqui release
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
      // chat
      logger.i('\n\ncreating chat server...');
      run('git clone https://github.com/growerp/growerp-chat $growerpPath/chatRelease');
      run('cp -r $growerpPath/chatRelease $growerpPath/chatDevelopment');
      run('git checkout development',
          workingDirectory: '$growerpPath/chatDevelopment');
    } else {
      logger
        ..i('updating local installation at $growerpPath')
        ..w('Your changes will be stashed.....get back with: git stash pop');
      run('git stash', workingDirectory: '$growerpPath/moquiDevelopment');
      run('./gradlew gitp', workingDirectory: '$growerpPath/moquiDevelopment');
      run('git stash', workingDirectory: '$growerpPath/moquiRelease');
      run('./gradlew gitp', workingDirectory: '$growerpPath/moquiRelease');
      run('git stash', workingDirectory: '$growerpPath/flutterDevelopment');
      run('git pull', workingDirectory: '$growerpPath/flutterRelease');
      run('git stash', workingDirectory: '$growerpPath/chatDevelopment');
      run('git pull', workingDirectory: '$growerpPath/chatDevelopment');
      run('git stash', workingDirectory: '$growerpPath/chatRelease');
      run('git pull', workingDirectory: '$growerpPath/chatRelease');
    }
    // run build just for development (prod is using pub.dev)

    logger.i('build flutter components in development');
    getPackageList().forEach((package) {
      run('flutter pub get', workingDirectory: package.fileLocation);
      run('flutter pub run build_runner build --delete-conflicting-outputs',
          workingDirectory: package.fileLocation);
    });
    // utils package rel/dev
    logger.i('build utils both dev and release');
    run('flutter pub get',
        workingDirectory: '$growerpPath/flutterDevelopment/packages/utils');
    run('flutter pub run build_runner build --delete-conflicting-outputs',
        workingDirectory: '$growerpPath/flutterDevelopment/packages/utils');
    run('flutter pub get',
        workingDirectory: '$growerpPath/flutterRelease/packages/utils');
    run('flutter pub run build_runner build --delete-conflicting-outputs',
        workingDirectory: '$growerpPath/flutterRelease/packages/utils');
    // start servers
    logger.i('start servers in seperate windows');
    run('gnome-terminal -- bash -c "cd $growerpPath/moquiDevelopment && java -jar moqui.war"');
    run('gnome-terminal -- bash -c "cd $growerpPath/chatDevelopment && ./gradlew apprun"');
    run('flutter run',
        workingDirectory: '$growerpPath/flutterDevelopment/packages/admin');
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    logger.e(e);
  }
}
