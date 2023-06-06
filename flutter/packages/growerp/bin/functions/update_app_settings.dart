import 'dart:io';

import '../models/models.dart';

void updateAppSettings() {
  final configFile = File(
      '$growerpPath/flutterDevelopment/packages/admin/assets/cfg/app_settings.json');
  final config = configFile.readAsLinesSync().toList();
  var newLine = '';
  final write = configFile.openWrite();
  for (final line in config) {
    newLine = line;
    if (line.contains('databaseUrlDebug')) {
      newLine = '"databaseUrlDebug": "https://test.growerp.org",\n';
    }
    if (line.contains('chatUrlDebug')) {
      newLine = '"chatUrlDebug": "wss://chat.growerp.org",\n';
    }
    write.write('$newLine\n');
  }
  write.close();
}
