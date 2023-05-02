#! /usr/bin/env dcli
// ignore_for_file: avoid_dynamic_calls

/// a command line script to run all tests available in the admin package
/// using the local package versions
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

import 'models/growerp_package_model.dart';

String getFileLocation(String fileString) {
  final home = Platform.environment['HOME'];
  final checks = fileString.split('/');
  final files = find(checks[checks.length - 1],
          types: [Find.file], workingDirectory: '$home/growerp')
      .toList();
  var returnFile = '';
  for (final file in files) {
    if (!file.contains('Development')) {
      continue;
    }
    var found = true;
    if (file.contains('Development')) {
      for (final check in checks) {
        if (!file.contains(check)) {
          found = false;
          break;
        }
      }
      if (found) {
        returnFile = file;
        break;
      }
    }
  }
  return returnFile;
}

List<GrowerpPackage> getComponentListDevelopment() {
  final home = Platform.environment['HOME'];
  final componentList = <GrowerpPackage>[];
  final client = PubClient();

  find('pubspec.yaml', types: [Find.file], workingDirectory: '$home/growerp')
      .forEach((file) async {
    if (file.contains('growerp_') &&
        file.contains('Development') &&
        !file.contains('build') &&
        !file.contains('example') &&
        !file.contains('growerp_select_dialog')) {
      final nameEnd = file.indexOf('/pubspec.yaml');
      final nameStart = file.substring(0, nameEnd).lastIndexOf('/') + 1;
      String packageName = file.substring(nameStart, nameEnd);
      PubPackage pubPackage = await client.packageInfo(packageName);
      dynamic pubSpec = loadYaml(File(file).readAsStringSync());

      componentList.add(GrowerpPackage(
          name: packageName,
          fileLocation: file.substring(0, nameEnd),
          pubVersion: pubPackage.version,
          version: pubSpec['version']));
    }
  });
  // move growerp_core to the beginning of the list
  var coreIndex = componentList.indexWhere((e) => e.name == 'growerp_core');
  var temp = componentList.first;
  componentList.first = componentList[coreIndex];
  componentList[coreIndex] = temp;
  return componentList;
}
