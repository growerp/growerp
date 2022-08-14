/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:io';

/* this script assums the following:

Moqui installed in $home/growerpMoqui
Chat installed in $home/growerpChat

android studio installed with emulator configured

*/

void main(List<String> arguments) async {
  var process;
  var emulator = 'pixel';
  if (arguments.isNotEmpty) emulator = arguments[0];

  var home = Platform.environment['HOME']!;

  // growerp already cloned or pulled
  // update growerp itself
  print("update growerp itself");
  await Process.runSync('git', ['stash'], workingDirectory: '$home/growerp');
  await Process.runSync('git', ['pull'], workingDirectory: '$home/growerp');
  await Process.runSync('flutter', ['pub', 'get'],
      workingDirectory: '$home/growerp/packages/core');
  await Process.runSync('flutter', ['pub', 'get'],
      workingDirectory: '$home/growerp/packages/admin');
  await Process.runSync('flutter',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: '$home/growerp/packages/core');

  // growerp-chat
  print("update chat");
  if (await Directory('$home/growerpChat').existsSync() == false) {
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/growerp-chat',
      '$home/growerpChat'
    ]);
  } else {
    process = await Process.runSync('git', ['pull'],
        workingDirectory: '$home/growerpChat');
    print('=========git pull chatServer: ${process.stdout}');
  }
  process = await Process.runSync('./gradlew', ['appRun'],
      workingDirectory: '$home/growerpChat');

  // growerp-moqui
  if (await Directory('$home/growerpMoqui').existsSync() == false) {
    print("create growerpMoqui backend system");
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-framework',
      '-b',
      'growerp',
      '$home/growerpMoqui'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-runtime',
      '$home/growerpMoqui/runtime'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/growerp-moqui',
      '$home/growerpMoqui/runtime/component/growerp'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/mantle-udm.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/mantle-udm'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/mantle-usl.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/mantle-usl'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/SimpleScreens.git',
      '$home/growerpMoqui/runtime/component/SimpleScreens'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/PopCommerce.git',
      '$home/growerpMoqui/runtime/component/PopCommerce'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/PopRestStore.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/PopRestStore'
    ]);
    process = await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-fop.git',
      '$home/growerpMoqui/runtime/component/moqui-fop'
    ]);
    process = await Process.runSync('./gradlew', ['downloadElasticSearch'],
        workingDirectory: '$home/growerpMoqui');
    print("build system");
    process = await Process.runSync('./gradlew', ['build'],
        workingDirectory: '$home/growerpMoqui');
    print('moqui build: ${process.stdout}');
  } else {
    process = await Process.runSync('git', ['stash'],
        workingDirectory: '$home/growerpMoqui/runtime/component/growerp');
    process = await Process.runSync('./gradlew', ['gitp'],
        workingDirectory: '$home/growerpMoqui');
  }

  process = await Process.runSync('./gradlew', ['cleandb'],
      workingDirectory: '$home/growerpMoqui');
  process = await Process.runSync(
      'java', ['-jar', 'moqui.war', 'load', 'types=seed,seed-initial,install'],
      workingDirectory: '$home/growerpMoqui');

  print('======= start moqui...');
  await Process.start('java', ['-jar', 'moqui.war'],
      workingDirectory: '$home/growerpMoqui', mode: ProcessStartMode.detached);

  print('======start emulator.....');
  process = await Process.start('flutter', ['emulators', '--launch', emulator]);

  print(' wait for emulator to start');
  await Future.delayed(Duration(seconds: 60));

  print('======start test....');
  await Process.start('flutter', ['test', 'integration_test/all_test.dart'],
      workingDirectory: '.', mode: ProcessStartMode.inheritStdio);
}
