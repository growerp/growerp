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

import 'dart:convert';
import 'dart:io';
import 'package:dcli/dcli.dart';

/// making screen shots with frames for IOS/Android
/// Android: uses all emulators available showing
///   with the 'flutter emulators' command
/// IOS: all emulators showing with the 'flutter devices' command
///   (need to start first)
void main(List<String> arguments) {
  final emulators = <String>[];
  exitCode = 0;
  print('Creating screen images from integration tests');
  const androidDir = 'android/fastlane/metadata/android/en-US/';
  const iosDir = 'ios/fastlane/unframed/en-US/';

  'flutter ${Platform.isMacOS ? "devices" : "emulators"}'
      .toList()
      .forEach((element) {
    if (!element.contains('*')) {
      print('No emulators/devices found');
      exit(1);
    }
    LineSplitter.split(element).forEach((line) {
      if (line.contains('•')) {
        emulators.addAll(line.split('•'));
      }
    });
    // remove empty first one in declaration
    emulators
      ..removeAt(0)
      // add entry to frame the images
      ..add('frameIt');
  });

  // clear directory
  final lister = Directory(Platform.isMacOS ? iosDir : androidDir).list();
  // ignore: cascade_invocations
  lister.listen((file) => {
        if (basename(file.path) != 'keyword.strings' &&
            basename(file.path) != 'images' &&
            basename(file.path) != 'changelogs' &&
            basename(file.path) != 'en-US' && // for ios
            basename(file.path) != 'title.strings')
          file.delete(),
      });

  void processEmulator(String imgPath, String emulatorId) {
    'flutter emulators --launch $emulatorId'.toList().forEach(print);

    waitForEx<void>(Future.delayed(const Duration(seconds: 10)));

    'flutter drive --driver=test_driver/menu_test.dart '
            '--target=test_driver/target.dart'
        .toList(workingDirectory: '$imgPath$emulatorId-')
        .forEach(print);

    'adb emu kill'.toList().forEach(print);
  }

  // process every emulator and then frameit
  for (final el in emulators) {
    if (el[0] != 'frameIt') {
      print('====screenshots for emulator ${el[0].trim()}');
      // frameit in last step
      if (el[3].trim() == 'android') {
        processEmulator(androidDir, el[0].trim());
      } else if (el[2].trim() == 'ios') {
        print('===executing IOS command: flutter drive -d ${el[1].trim()} ');
        'flutter drive -d ${el[1].trim()} '
                '--driver=test_driver/menu_test.dart '
                '--target=test_driver/target.dart '
            .toList(workingDirectory: '$iosDir${el[0].trim()}-')
            .forEach(print);
      }
    } else {
      print('===frame the images');
      if (Platform.isMacOS) {
        'flutter pub global run '
                'frameit_chrome '
                '--base-dir=ios/fastlane/unframed '
                '--frames-dir=ios/fastlane/frames '
                '--chrome-binary=/Applications/Google '
                'Chrome.app/Contents/MacOS/Google  Chrome '
                '--pixel-ratio=2'
            .toList()
            .forEach(print);
      } else {
        'flutter pub global run frameit_chrome '
                '--base-dir=android/fastlane/metadata/android '
                '--frames-dir=android/fastlane/frames '
                '--chrome-binary=/usr/bin/google-chrome-stable '
                '--pixel-ratio=1'
            .toList()
            .forEach(print);
      }
    }
  }
}
