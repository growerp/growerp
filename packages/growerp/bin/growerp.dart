import 'functions/functions.dart';
import 'models/models.dart';

void main(List<String> args) {
  var newArgs = List.of(args);
  if (newArgs.isEmpty) {
    print('Please enter a GrowERP command? valid commands are:'
        ' install | switchPackage');
  } else {
    // flags
    Environment? env;
    var index = newArgs.indexOf('-dev');
    if (index > 0) {
      newArgs.removeAt(index);
      env = Environment.development;
    }
    index = newArgs.indexOf('-rel');
    if (index > 0) {
      newArgs.removeAt(index);
      env = Environment.release;
    }

    var start = false;
    index = newArgs.indexOf('-start');
    if (index > 0) {
      newArgs.removeAt(index);
      start = true;
    }

    final index1 = newArgs.indexWhere((element) => element.startsWith('-'));
    if (index1 > 0) {
      print('flag ${args[index1]} not recognized');
      return;
    }

    // commands
    switch (args[0].toLowerCase()) {
      case 'install':
        {
          if (newArgs.length > 1) {
            if (['frontend', 'full', 'backend', 'chat']
                .contains(args[1].toLowerCase())) {
              switch (args[1]) {
                case 'full':
                  print('Full installation: in the $growerpPath directory');
                  createChatEnv(start: start, env: env);
                  createMoquiEnv(start: start, env: env);
                  createFlutterEnv(start: start, env: env);
                  break;
                case 'frontend':
                  print('Installing just the flutter frontend at $growerpPath '
                      'using GrowERP public backend');
                  createFlutterEnv(start: start, env: env);
                  break;
                case 'backend':
                  print('Installing just the moqui backend at $growerpPath');
                  createMoquiEnv(start: start, env: env);
                  break;
                case 'chat':
                  print('Installing just the chat server at $growerpPath');
                  createChatEnv(start: start, env: env);
                  break;
              }
            }
          } // default install, just frontend
          else {
            print('Installing just the flutter frontend at $growerpPath ');
            createFlutterEnv(start: start, env: env);
          }
          break;
        }
      case 'switchpackage':
      case 'sp':
        {
          switchPackage();
          break;
        }
      default:
        {
          print('${args[0]} is not a valid command, valid commands are:'
              ' install | switchPackage');
        }
    }
  }
}
