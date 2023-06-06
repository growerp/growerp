import 'dart:io';
import 'package:dcli/dcli.dart';

import '../models/models.dart';
import 'functions.dart';

/// create a development and or release environment with flutter frontend
/// when no moqui enviroment exists the system will be reconfigured
/// to use the growerp test backend.
void createFlutterEnv(
    {required Environment env, bool start = false, bool build = true}) {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (env == Environment.full || env == Environment.release) {
    getFlutterFiles('flutterRelease');
  }
  if (env == Environment.full || env == Environment.development) {
    getFlutterFiles('flutterDevelopment');
    if (build) {
      buildFlutter('flutterDevelopment');
    }
    // change config to use growerp test backend
    if (!exists('$growerpPath/moquiDevelopment')) {
      updateAppSettings();
    }
    // start admin flutter in new window
    run('flutter pub get',
        workingDirectory: '$growerpPath/flutterDevelopment/packages/admin');
    if (start && Platform.isLinux) {
      logger.i('Starting flutter in different window....');
      run('gnome-terminal -- bash -c "cd $growerpPath/flutterDevelopment/packages/admin && flutter run"');
    }
  }
}
