#! /usr/bin/env dcli
// ignore_for_file: avoid_dynamic_calls

/// a command line script to run all tests available in the admin package
/// using the local package versions
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

import 'functions.dart';

Logger logger = Logger(
  printer: PrettyPrinter(),
);

final home = Platform.environment['HOME'];

main(List<String> args) {
  logger.i('creating a release and development environment\n'
      'all files are in the home/growerp directory\n'
      'flutter/development & flutter/release: flutter\n'
      'moqui/development moqui/release moqui backend\n'
      'chat/development chat/release chat server\n'
      'creating growerp...');

  try {
    if (!exists('$home/growerp')) {
      logger.i('creating flutter part...');
      // growerp
      run('mkdir $home/growerp');
      run('git clone https://github.com/growerp/growerp.git '
          '$home/growerp/flutterRelease');
      run('cp -r $home/growerp/flutterRelease '
          '$home/growerp/flutterDevelopment');
      run('git checkout development',
          workingDirectory: '$home/growerp/flutterDevelopment');
      // moqui release
      logger.i('creating moqui release...');
      run('git clone -b growerp https://github.com/growerp/moqui-framework.git '
          '$home/growerp/moquiRelease');
      run('git clone https://github.com/growerp/moqui-runtime '
          '$home/growerp/moquiRelease/runtime');
      run('git clone https://github.com/growerp/growerp-moqui.git '
          '$home/growerp/moquiRelease/runtime/component/growerp');
      run('git clone -b growerp https://github.com/growerp/PopRestStore.git '
          '$home/growerp/moquiRelease/runtime/component/PopRestStore');
      run('git clone -b growerp https://github.com/growerp/mantle-udm.git'
          ' -b growerp $home/growerp/moquiRelease/runtime/component/mantle-udm');
      run('git clone -b growerp https://github.com/growerp/mantle-usl.git '
          '$home/growerp/moquiRelease/runtime/component/mantle-usl');
      run('git clone https://github.com/growerp/mantle-stripe.git '
          '$home/growerp/moquiRelease/runtime/component/mantle-stripe');
      run('git clone https://github.com/growerp/moqui-fop.git '
          '$home/growerp/moquiRelease/runtime/component/moqui-fop');
      run('./gradlew downloadElasticSearch',
          workingDirectory: '$home/growerp/moquiRelease');
      logger.i('building moqui release...');
      run('./gradlew build', workingDirectory: '$home/growerp/moquiRelease');
      run('java -jar moqui.war load types=seed,seed-initial,install',
          workingDirectory: '$home/growerp/moquiRelease');
      logger.i('creating moqui development...');
      // moqui development copy from release and switch branch
      run('cp -r $home/growerp/moquiRelease $home/growerp/moquiDevelopment');
      run('git checkout development',
          workingDirectory:
              '$home/growerp/moquiRelease/runtime/component/growerp');
      logger.i('building moqui release...');
      run('./gradlew build',
          workingDirectory: '$home/growerp/moquiDevelopment');
      run('java -jar moqui.war load types=seed,seed-initial,install',
          workingDirectory: '$home/growerp/moquiDevelopment');
      // chat
      logger.i('creating dev/rel chat server...');
      run('git clone https://github.com/growerp/growerp-chat $home/growerp/chatRelease');
      run('cp -r $home/growerp/chatRelease $home/growerp/chatDevelopment');
      run('git checkout development',
          workingDirectory: '$home/growerp/chatDevelopment');
    } else {
      logger.i('updating local installation from github at $home/growerp');
      logger.w('Your changes will be stashed.....get back with: git stash pop');
      run('git stash', workingDirectory: '$home/growerp/moquiDevelopment');
      run('./gradlew gitp', workingDirectory: '$home/growerp/moquiDevelopment');
      run('git stash', workingDirectory: '$home/growerp/moquiRelease');
      run('./gradlew gitp', workingDirectory: '$home/growerp/moquiRelease');
      run('git stash', workingDirectory: '$home/growerp/flutterDevelopment');
      run('git pull', workingDirectory: '$home/growerp/flutterRelease');
    }
    // run build just for development (prod is using pub.dev)

    logger.i('build flutter components in development');
    getComponentListDevelopment().forEach((package) {
      run('flutter pub get', workingDirectory: package.fileLocation);
      run('flutter pub run build_runner build --delete-conflicting-outputs',
          workingDirectory: package.fileLocation);
    });
    // utils package rel/dev
    logger.i('build utils both dev and release');
    run('flutter pub get',
        workingDirectory: '$home/growerp/flutterDevelopment/packages/utils');
    run('flutter pub run build_runner build --delete-conflicting-outputs',
        workingDirectory: '$home/growerp/flutterDevelopment/packages/utils');
    run('flutter pub get',
        workingDirectory: '$home/growerp/flutterRelease/packages/utils');
/*  build runner missing in production TODO: remove this comment with next release  
    run('flutter pub run build_runner build --delete-conflicting-outputs',
        workingDirectory: '$home/growerp/flutterRelease/packages/utils');
*/ // start servers
    if (Platform.isLinux) {
      logger.i("start servers in seperate terminal...");
      run('gnome-terminal -- bash -c "cd $home/growerp/moquiDevelopment && java -jar moqui.war"');
      run('gnome-terminal -- bash -c "cd $home/growerp/chatDevelopment && ./gradlew apprun"');
      run('flutter run',
          workingDirectory: '$home/growerp/flutterDevelopment/packages/admin');
    } else {
      logger.i('GrowERP Installed but not started');
      logger.i('Create 3 command line windows:');
      logger.i(
          "Moqui backend in directory moquiDevelopment: java -jar moqui.war");
      logger.i("Chat backend in directory chatDevelopment: gradlew appRun");
      logger
          .i("Flutter front-end in directory flutterDevelopment: flutter run");
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    logger.e(e);
  }
}
