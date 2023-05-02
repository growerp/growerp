#! /usr/bin/env dcli
// ignore_for_file: avoid_dynamic_calls

/// a command line script to run all tests available in the admin package
/// using the local package versions
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml_modify/yaml_modify.dart';

const logFile = 'all_test.log';
Future<void> main(List<String> args) async {
  'rm $logFile'.toList(nothrow: true);
  var production = true;
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
  final pkgList = getComponentListDevelopment();
  var coreVersion = '';
  for (final package in pkgList) {
    if (package.name == 'growerp_core') {
      coreVersion = package.version;
      break;
    }
  }
  for (final package in pkgList) {
    final pkgFileName =
        getFileLocation('packages/${package.name}/pubspec.yaml');
    final pkgFile = File(pkgFileName);
    final dynamic pkgYaml = loadYaml(pkgFile.readAsStringSync());
    final dynamic pkgModifiable = getModifiableNode(pkgYaml);

    if (production) {
      if (package.name != 'growerp_core') {
        pkgModifiable['dependencies']['growerp_core'] = '^$coreVersion';
      }
      adminModifiable['dependencies'][package.name] = '^${package.version}';
    } else {
      if (package.name != 'growerp_core') {
        pkgModifiable['dependencies']
            ['growerp_core'] = {'path': '../growerp_core/'};
      }
      adminModifiable['dependencies']
          [package.name] = {'path': '../${package.name}/'};
    }
    final pkgStrYaml = toYamlString(pkgModifiable);
    File(pkgFileName).writeAsStringSync(pkgStrYaml);
    //print(pkgStrYaml);
  }
  final strYaml = toYamlString(adminModifiable);
  File(adminFileName).writeAsStringSync(strYaml);
  //print(strYaml);
}

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

List<PubPackage> getComponentListDevelopment() {
  final home = Platform.environment['HOME'];
  final componentList = <PubPackage>[];
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
      componentList
          .add(await client.packageInfo(file.substring(nameStart, nameEnd)));
    }
  });
  return componentList;
}
