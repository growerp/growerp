import 'dart:io';
import 'package:dcli/dcli.dart';

import '../models/models.dart';
import 'functions.dart';

void buildFlutter(String targetDir) {
  if (targetDir == 'flutterDevelopment') {
    logger.i('building packages in development...');
    final packages = getPackageList('$growerpPath/$targetDir/packages');
    if (packages.isEmpty) {
      logger.e('No packages could be build, pub.dev limit reached? '
          'try later again');
      exit(1);
    }
    for (final package in packages) {
      logger.i('building package: ${package.name}');
      run('flutter pub get', workingDirectory: package.fileLocation);
      if (package.buildRunner) {
        // has buildrunner installed?
        run('flutter pub run build_runner build --delete-conflicting-outputs',
            workingDirectory: package.fileLocation);
      }
    }
  }
}
