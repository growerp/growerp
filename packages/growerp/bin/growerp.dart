import 'functions/functions.dart';
import 'models/globals.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please enter a GrowERP command?');
  } else {
    if (args[0] == 'install') {
      if (args.length > 1) {
        if (['frontend', 'full'].contains(args[1].toLowerCase())) {
          if (args[1] == 'full') {
            print('Full installation: in the $growerpPath directory');
            createFlutterEnv();
            createChatEnv();
            createMopquiEnv();
          } else {
            print('Installing just the flutter frontend at $growerpPath '
                'using GrowERP public backend');
            createFlutterEnv();
          }
        } else {
          print('Command format : growerp install frontend | full');
        }
      } // default install, just frontend
      else {
        print('Installing just the flutter frontend at $growerpPath '
            'using GrowERP public backend');
        createFlutterEnv();
      }
    } else {
      print('${args[0]} is not a valid command, valid commands are: install');
    }
  }
}
