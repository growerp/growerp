// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

import '../models/growerp_package_model.dart';

/// getGrowerpPackageInfo expect a [PubClient] and
/// fileLocation of package
Future<GrowerpPackage> getGrowerpPackageInfo(
    PubClient client, String directoryLocation) async {
  PubPackage? pubPackage;
  final packageName =
      directoryLocation.substring(directoryLocation.lastIndexOf('/') + 1);
  final dynamic pubSpec =
      loadYaml(File('$directoryLocation/pubspec.yaml').readAsStringSync());
  if (!(pubSpec['publish_to'] != null && pubSpec['publish_to'] == 'none')) {
    pubPackage = await client.packageInfo(packageName);
  }
  var buildRunner = true;
  if (pubSpec['dev_dependencies']['build_runner'] == null) {
    buildRunner = false;
  }

  return GrowerpPackage(
      name: packageName,
      fileLocation: directoryLocation,
      pubVersion: pubPackage != null ? pubPackage.latest.version : '',
      pubDate:
          pubPackage != null ? pubPackage.latest.published : DateTime(2000),
      buildRunner: buildRunner,
      version: pubSpec['version'] as String);
}
