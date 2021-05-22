import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

void main(List<String> arguments) {
  var emulators = [[]];
  exitCode = 0;
  print('Creating screen images from integration tests');
  const androidDir = 'android/fastlane/metadata/android/en-US/';

  Process.run('flutter', ['emulators']).then((ProcessResult rs) async {
    if (!rs.stdout.contains('•')) {
      print('No emulators found');
      exit(rs.exitCode);
    }
    LineSplitter.split(rs.stdout).forEach((line) {
      if (line.contains('•')) emulators.add(line.split('•'));
    });
    // remove empty first one in declaration
    emulators.removeAt(0);
    // add entry to frame the images
    emulators.add(['frameIt']);

    // run integration test by providing path to store screenshots
    Future<void> ProcessEmulator(String imgPath, String emulatorId) async {
      await Future.forEach([
        // start emulator
        {
          'executable': 'flutter',
          'arguments': ['emulators', '--launch', emulatorId],
          'wait': 10
        },
        // run integration test
        {
          'executable': 'flutter',
          'arguments': ['driver'],
          'environment': {'imagePrefix': '$imgPath$emulatorId-'}
        },
        // close emulator
        {
          'executable': 'adb',
          'arguments': ['emu', 'kill']
        }
      ], (Map el) async {
        print("executing command ${el['executable']} ${el['arguments']}");
        var result = await Process.start(el['executable'], el['arguments'],
            environment: el['environment']);
        await stdout.addStream(result.stdout);
        if (el['wait'] != null) {
          await Future.delayed(Duration(seconds: el['wait']));
        }
      });
    }

    // clear directory
    var lister = Directory(androidDir).list(recursive: false);
    lister.listen((file) => {
          if (basename(file.path) != 'keyword.strings' &&
              basename(file.path) != 'images' &&
              basename(file.path) != 'title.strings')
            file.delete(),
        });

    // process every emulator and then frameit
    await Future.forEach(emulators, (List el) async {
      if (el[0] != 'frameIt') {
        // frameit in last step
        if (el[3].trim() == 'android') {
          print(
              '====processing emulator ${el[0].trim()} with path: $androidDir');
          await ProcessEmulator(androidDir, el[0].trim());
        } else {
          print('==== ${el[3].trim()} not implemented yet!');
        }
      } else {
        print('===frame the images');
        var result = await Process.start(
          'flutter',
          [
            'pub',
            'global',
            'run',
            'frameit_chrome',
            '--base-dir=android/fastlane/metadata/android',
            '--frames-dir=android/fastlane/frames',
            '--chrome-binary=/usr/bin/google-chrome-stable',
            '--pixel-ratio=1'
          ],
        );
        await stdout.addStream(result.stdout);
      }
    });
  });
}
