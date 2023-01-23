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
flutter installed at $home/growerp

android studio installed with emulator 'Pixel 4' configured

*/

void main(List<String> arguments) async {
  var process;
  var emulator = 'Pixel 4';
  if (arguments.isNotEmpty) emulator = arguments[0];

  var home = Platform.environment['HOME']!;

  // growerp already cloned or pulled
  // update growerp itself
  print("update growerp itself");
  await Process.runSync('git', ['stash'], workingDirectory: '$home/growerp');
  await Process.runSync('git', ['pull'], workingDirectory: '$home/growerp');
  await Process.runSync('flutter', ['pub', 'get'],
      workingDirectory: '$home/growerp/packages/admin');

  // growerp-chat
  print("update chat");
  if (await Directory('$home/growerpChat').existsSync() == false) {
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/growerp-chat',
      '$home/growerpChat'
    ]);
  } else {
    await Process.runSync('git', ['pull'],
        workingDirectory: '$home/growerpChat');
  }
  await Process.runSync('./gradlew', ['appRun'],
      workingDirectory: '$home/growerpChat');

  // growerp-moqui
  if (await Directory('$home/growerpMoqui').existsSync() == false) {
    print("create growerpMoqui backend system");
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-framework',
      '-b',
      'growerp',
      '$home/growerpMoqui'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-runtime',
      '$home/growerpMoqui/runtime'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/growerp-moqui',
      '$home/growerpMoqui/runtime/component/growerp'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/mantle-udm.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/mantle-udm'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/mantle-usl.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/mantle-usl'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/SimpleScreens.git',
      '$home/growerpMoqui/runtime/component/SimpleScreens'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/PopRestStore.git',
      '-b',
      'growerp',
      '$home/growerpMoqui/runtime/component/PopRestStore'
    ]);
    await Process.runSync('git', [
      'clone',
      'https://github.com/growerp/moqui-fop.git',
      '$home/growerpMoqui/runtime/component/moqui-fop'
    ]);
    await Process.runSync('./gradlew', ['downloadElasticSearch'],
        workingDirectory: '$home/growerpMoqui');
    print("built system");
    process = await Process.runSync('./gradlew', ['build'],
        workingDirectory: '$home/growerpMoqui');
    print('moqui build: ${process.stdout}');
  } else {
    print("update existing growerpMoqui backend system");
    await Process.runSync('git', ['stash'],
        workingDirectory: '$home/growerpMoqui/runtime/component/growerp');
    process = await Process.runSync('./gradlew', ['gitp'],
        workingDirectory: '$home/growerpMoqui');
    print('moqui updated: ${process.stdout}');
  }

  await Process.runSync('./gradlew', ['cleandb'],
      workingDirectory: '$home/growerpMoqui');
  await Process.runSync(
      'java', ['-jar', 'moqui.war', 'load', 'types=seed,seed-initial,install'],
      workingDirectory: '$home/growerpMoqui');

  print('======= start moqui...');
  await Process.start('java', ['-jar', 'moqui.war'],
      workingDirectory: '$home/growerpMoqui', mode: ProcessStartMode.detached);

  print('======start emulator.....');
  await Process.start('flutter', ['emulators', '--launch', emulator]);

  print(' wait for emulator to start');
  await Future.delayed(Duration(seconds: 60));

  print('======start test....');
  await Process.start('flutter', ['test', 'integration_test/all_test.dart'],
      workingDirectory: '.', mode: ProcessStartMode.inheritStdio);
}
