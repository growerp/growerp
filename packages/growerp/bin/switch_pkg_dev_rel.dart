#! /usr/bin/env dcli

// ignore_for_file: avoid_dynamic_calls
import 'dart:io';
import 'package:yaml_modify/yaml_modify.dart';

import 'functions/functions.dart';

const logFile = 'all_test.log';
Future<void> main(List<String> args) async {
  var production = true;
  // switch admin app
  final adminFileName = getFileLocation('packages/admin/pubspec.yaml');
  if (adminFileName.isEmpty) {
    print('could not find packages/admin/pubspec.yaml');
    return;
  }
  final adminFile = File(adminFileName);
  final dynamic adminYaml = loadYaml(adminFile.readAsStringSync());
  if (adminYaml['dependencies']['growerp_core'].toString().contains('path') ==
      true) {
    print('==== switch to production using pub.dev ===');
  } else {
    print('==== switch to test using path ===');
    production = false;
  }
  final dynamic adminModifiable = getModifiableNode(adminYaml);
  final pkgList = getPackageList();
  // first item in list is growerp_core
  final coreVersion = pkgList[0].pubVersion;
  for (final package in pkgList) {
    final pkgFile = File(package.fileLocation);
    final dynamic pkgYaml = loadYaml(pkgFile.readAsStringSync());
    if (pkgYaml['dependencies']['growerp_core'] == null) {
      continue;
    }
    final dynamic pkgModifiable = getModifiableNode(pkgYaml);

    if (production) {
      pkgModifiable['dependencies']['growerp_core'] = '^$coreVersion';
      adminModifiable['dependencies'][package.name] = '^${package.version}';
    } else {
      pkgModifiable['dependencies']
          ['growerp_core'] = {'path': '../growerp_core/'};
      adminModifiable['dependencies']
          [package.name] = {'path': '../${package.name}/'};
    }
    final pkgStrYaml = toYamlString(pkgModifiable);
    File(package.fileLocation).writeAsStringSync(pkgStrYaml);
    //print(pkgStrYaml);
  }
  final strYaml = toYamlString(adminModifiable);
  File(adminFileName).writeAsStringSync(strYaml);
  //print(strYaml);
}
