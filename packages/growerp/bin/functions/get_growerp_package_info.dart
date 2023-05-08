// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

import '../models/growerp_package_model.dart';

/// getGrowerpPackageInfo expect a [PubClient] and
/// fileLocation of package
Future<GrowerpPackage> getGrowerpPackageInfo(
    PubClient client, String directoryLocation) async {
  final packageName =
      directoryLocation.substring(directoryLocation.lastIndexOf('/') + 1);
  final dynamic pubSpec =
      loadYaml(File('$directoryLocation/pubspec.yaml').readAsStringSync());
  final pubPackage = await client.packageInfo(packageName);
  var buildRunner = true;
  if (pubSpec['dev_dependencies']['build_runner'] == null) {
    buildRunner = false;
  }

  return GrowerpPackage(
      name: packageName,
      fileLocation: directoryLocation,
      pubVersion: pubPackage.latest.version,
      pubDate: pubPackage.latest.published,
      buildRunner: buildRunner,
      version: pubSpec['version'] as String);
}
