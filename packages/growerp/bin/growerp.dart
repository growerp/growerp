import 'functions/functions.dart';
import 'models/globals.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please enter a GrowERP command? valid commands are:'
        ' install | switchPackage');
  } else {
    switch (args[0].toLowerCase()) {
      case 'install':
        {
          if (args.length > 1) {
            if (['frontend', 'full', 'backend']
                .contains(args[1].toLowerCase())) {
              switch (args[1]) {
                case 'full':
                  print('Full installation: in the $growerpPath directory');
                  createChatEnv();
                  createMopquiEnv();
                  createFlutterEnv();
                  break;
                case 'frontend':
                  print('Installing just the flutter frontend at $growerpPath '
                      'using GrowERP public backend');
                  createFlutterEnv();
                  break;
                case 'backend':
                  print('Installing just the flutter backend at $growerpPath');
                  createChatEnv();
                  createMopquiEnv();
                  break;
              }
            } else {
              print(
                  'Command format : growerp install frontend | full | backend');
            }
          } // default install, just frontend
          else {
            print('Installing just the flutter frontend at $growerpPath '
                'using GrowERP public backend');
            createFlutterEnv();
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
