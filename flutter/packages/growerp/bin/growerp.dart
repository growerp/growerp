import 'functions/functions.dart';
import 'models/models.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please enter a GrowERP command? valid commands are:'
        ' install | switchPackage');
  } else {
    final modifiedArgs = <String>[];
    var env = Environment.full;
    var start = false;
    var build = true;
    for (final arg in args) {
      switch (arg) {
        case '-dev':
          env = Environment.development;
          break;
        case '-rel':
          env = Environment.release;
          break;
        case '-start':
          start = true;
          break;
        case '-noBuild':
        case '-nobuild':
          build = false;
          break;
        default:
          if (arg.startsWith('-')) {
            print('flag $arg not recognized');
          } else {
            modifiedArgs.add(arg);
          }
      }
    }
    print('Flags: -noBuild: ${!build} -start: $start env: $env');

    // commands
    switch (modifiedArgs[0].toLowerCase()) {
      case 'install':
        {
          if (modifiedArgs.length > 1) {
            switch (GrowerpPart.parse(modifiedArgs[1])) {
              case GrowerpPart.all:
                print('Full installation: in the $growerpPath directory');
                createChatEnv(start: start, env: env);
                createMoquiEnv(start: start, env: env, build: build);
                createFlutterEnv(start: start, env: env, build: build);
                break;
              case GrowerpPart.frontend:
                print('Installing just the flutter frontend at $growerpPath '
                    'using GrowERP public backend');
                createFlutterEnv(start: start, env: env, build: build);
                break;
              case GrowerpPart.backend:
                print('Installing just the moqui backend at $growerpPath');
                createMoquiEnv(start: start, env: env, build: build);
                break;
              case GrowerpPart.chat:
                print('Installing just the chat server at $growerpPath');
                createChatEnv(start: start, env: env);
                break;
              case GrowerpPart.unknown:
                print('not recognized install parameter: ${modifiedArgs[0]}');
            }
          } else {
            print('Installing just the flutter frontend at $growerpPath ');
            createFlutterEnv(start: start, env: env, build: build);
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
          print('${modifiedArgs[0]} is not a valid command, valid commands are:'
              ' install | switchPackage');
        }
    }
  }
}
