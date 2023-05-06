// ignore_for_file: avoid_dynamic_calls

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

import '../models/globals.dart';
import '../models/growerp_package_model.dart';

List<GrowerpPackage> getPackageList() {
  final componentList = <GrowerpPackage>[];
  final client = PubClient();

  find('pubspec.yaml', types: [Find.file], workingDirectory: growerpPath)
      .forEach((file) async {
    if (file.contains('flutterDevelopment/packages/growerp') &&
        !file.contains('build') &&
        !file.contains('example')) {
      final nameEnd = file.indexOf('/pubspec.yaml');
      final nameStart = file.substring(0, nameEnd).lastIndexOf('/') + 1;
      final packageName = file.substring(nameStart, nameEnd);
      final pubPackage = await client.packageInfo(packageName);
      final dynamic pubSpec = loadYaml(File(file).readAsStringSync());
      var buildRunner = true;
      if (pubSpec['dev_dependencies']['build_runner'] == null) {
        buildRunner = false;
      }

      componentList.add(GrowerpPackage(
          name: packageName,
          fileLocation: file.substring(0, nameEnd),
          pubVersion: pubPackage.latest.version,
          pubDate: pubPackage.latest.published,
          buildRunner: buildRunner,
          version: pubSpec['version'] as String));
    }
  });
  // move growerp_core to the beginning of the list
  if (componentList.isNotEmpty) {
    final coreIndex = componentList.indexWhere((e) => e.name == 'growerp_core');
    final temp = componentList.first;
    componentList.first = componentList[coreIndex];
    componentList[coreIndex] = temp;
  } else {
    logger.e('no packages found?');
  }
  return componentList;
}
