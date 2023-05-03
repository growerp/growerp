import 'package:dcli/dcli.dart';

import '../models/globals.dart';

void createChatEnv() {
  if (!exists(growerpPath)) {
    run('mkdir $growerpPath');
  }
  if (!exists('$growerpPath/chatDevelopment')) {
    logger.i('creating chat server...');
    run('git clone https://github.com/growerp/growerp-chat $growerpPath/chatRelease');
    run('cp -r $growerpPath/chatRelease $growerpPath/chatDevelopment');
    run('git checkout development',
        workingDirectory: '$growerpPath/chatDevelopment');
  } else {
    logger
      ..i('updating local installation at $growerpPath/chat*')
      ..w('Your changes will be stashed.....get back with: git stash pop');
    run('git stash', workingDirectory: '$growerpPath/chatDevelopment');
    run('git pull', workingDirectory: '$growerpPath/chatDevelopment');
    run('git stash', workingDirectory: '$growerpPath/chatRelease');
    run('git pull', workingDirectory: '$growerpPath/chatRelease');
  }
}
