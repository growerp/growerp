import 'package:dcli/dcli.dart';

import '../models/models.dart';

String getFileLocation(String fileString) {
  final checks = fileString.split('/');
  // find filename out of provided path
  final files = find(checks[checks.length - 1],
          types: [Find.file],
          workingDirectory: '$growerpPath/flutterDevelopment')
      .toList();
  var returnFile = '';
  for (final file in files) {
    var found = true;
    // check for all directories
    for (final check in checks) {
      if (!file.contains(check)) {
        found = false;
        break;
      }
      // still found return
      if (found) {
        returnFile = file;
        break;
      }
    }
  }
  return returnFile;
}
