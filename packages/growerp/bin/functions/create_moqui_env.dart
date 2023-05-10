import 'dart:io';

import 'package:dcli/dcli.dart';

import '../functions/functions.dart';
import '../models/models.dart';

/// create a development and/or production envronment for
/// the moqui backend system and optionally build it and load
/// database with initial data
void createMoquiEnv(
    {required Environment env, bool start = false, bool build = false}) {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (env == Environment.full || env == Environment.release) {
    getMoquiFiles('moquiRelease', build: build);
  }
  if (env == Environment.full || env == Environment.development) {
    getMoquiFiles('moquiDevelopment', build: build);
    if (start && Platform.isLinux) {
      logger.i('Starting Moqui in different window....');
      run('gnome-terminal -- bash -c "cd $growerpPath/moquiDevelopment && java -jar moqui.war"');
    }
  }
}
