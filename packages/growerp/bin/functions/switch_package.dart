// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

import '../models/models.dart';
import 'functions.dart';

/// will change all packages in development including the app 'admin'
/// from version in pub.dev to a local path and vice versa
Future<void> switchPackage() async {
  var production = true;
  // switch admin app
  final adminDirectory = '$growerpPath/flutterDevelopment/packages/admin';
  final hotelDirectory = '$growerpPath/flutterDevelopment/packages/hotel';
  final adminGrowerpPackage =
      await getGrowerpPackageInfo(PubClient(), adminDirectory);
  final hotelGrowerpPackage =
      await getGrowerpPackageInfo(PubClient(), hotelDirectory);
  final adminFile = File('$adminDirectory/pubspec.yaml');
  final dynamic adminYaml = loadYaml(adminFile.readAsStringSync());
  // check to see if switch to dev or switch to release
  if (adminYaml['dependencies']['growerp_core'] == null) {
    print("Could not find dependency growerp_core in admin app'");
    return;
  }
  if (adminYaml['dependencies']['growerp_core'].toString().contains('path')) {
    print('switch to production using pub.dev');
  } else {
    print('switch to test using path');
    production = false;
  }
  final pkgList = getPackageList('$growerpPath/flutterDevelopment/packages')
    ..add(adminGrowerpPackage)
    ..add(hotelGrowerpPackage);
  if (pkgList.isEmpty) {
    print('No packages could be found, pub.dev limit reached? try later again');
    exit(1);
  }
  for (final package in pkgList) {
    final pkgFile = File('${package.fileLocation}/pubspec.yaml');
    final dynamic pkgYaml = loadYaml(pkgFile.readAsStringSync());
    final dynamic pkgModifiable = getModifiableNode(pkgYaml);
    // modify all references in the packages
    for (final package in pkgList) {
      if (pkgYaml['dependencies'][package.name] != null) {
        if (production) {
          pkgModifiable['dependencies'][package.name] =
              '^${package.pubVersion}';
        } else {
          pkgModifiable['dependencies']
              [package.name] = {'path': '../${package.name}/'};
        }
      }
    }
    final pkgStrYaml = toYamlString(pkgModifiable);
    File('${package.fileLocation}/pubspec.yaml').writeAsStringSync(pkgStrYaml);
  }
}
