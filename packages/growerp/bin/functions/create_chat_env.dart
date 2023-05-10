import 'dart:io';

import 'package:dcli/dcli.dart';

import '../models/models.dart';

void createChatEnv({required Environment env, bool start = false}) {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (env == Environment.full || env == Environment.development) {
    if (!exists('$growerpPath/chatDevelopment')) {
      logger.i('creating chat development server...');
      run('git clone -b development https://github.com/growerp/growerp-chat $growerpPath/chatDevelopment');
    } else {
      logger
        ..i('updating local development installation at $growerpPath/chatDevelopment*')
        ..w('Your changes will be stashed.....get back with: git stash pop');
      run('git stash', workingDirectory: '$growerpPath/chatDevelopment');
      run('git pull', workingDirectory: '$growerpPath/chatDevelopment');
    }
    if (start) {
      if (Platform.isLinux) {
        logger.i('Starting development chat in different window....');
        run('gnome-terminal -- bash -c "cd $growerpPath/chatDevelopment && ./gradlew apprun"');
      } else {
        logger.i('automatic start currently on available in Linux.\n'
            'manually: open new terminal, cd $growerpPath/chatDevelopment , gradlew apprun');
      }
    }
  }

  if (env == Environment.full || env == Environment.release) {
    if (!exists('$growerpPath/chatRelease')) {
      logger.i('creating chat release server...');
      run('git clone https://github.com/growerp/growerp-chat $growerpPath/chatRelease');
    } else {
      logger
        ..i('updating local release installation at $growerpPath/chatRelease')
        ..w('Your changes will be stashed.....get back with: git stash pop');
      run('git stash', workingDirectory: '$growerpPath/chatRelease');
      run('git pull', workingDirectory: '$growerpPath/chatRelease');
    }
  }
}
