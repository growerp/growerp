#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';

const logFile = 'all_test.log';
void main(List<String> args) {
  'rm $logFile'.toList(nothrow: true);
  final home = Platform.environment['HOME'];
  // process growerp_core first
  find('all_test.dart', types: [Find.file], workingDirectory: '$home/growerp')
      .forEach((file) {
    if (file.contains('/growerp_core') && file.contains('Development')) {
      processComponent(file);
    }
  });
  // process the others
  find('all_test.dart', types: [Find.file], workingDirectory: '$home/growerp')
      .forEach((file) {
    if (file.contains('/growerp_') &&
        !file.contains('/growerp_core') &&
        file.contains('Development')) {
      processComponent(file);
    }
  });
  'cat $logFile'.run;
}

void processComponent(String allTestFile) {
  final fileSync = FileSync(logFile);
  final wdEnd = allTestFile.indexOf('/integration_test/all_test.dart');
  final pkgEnd = allTestFile.indexOf('/example/integration_test/all_test.dart');
  final nameEnd =
      allTestFile.indexOf('/example/integration_test/all_test.dart');
  final nameStart = allTestFile.substring(0, nameEnd).lastIndexOf('/') + 1;
  print('====Processing: ${allTestFile.substring(nameStart, nameEnd)}');
  fileSync.append(
      '=========processing ${allTestFile.substring(nameStart, nameEnd)}======');
  try {
    // build component
    'flutter pub get'
        .toList(workingDirectory: allTestFile.substring(0, pkgEnd));
    'flutter pub run build_runner build --delete-conflicting-outputs'
        .toList(workingDirectory: allTestFile.substring(0, pkgEnd));
    // run test
    final results = 'flutter test $allTestFile'
        .toList(workingDirectory: allTestFile.substring(0, wdEnd));
    for (final line in results) {
      if (line.contains('[E]') || line.contains('skipped')) {
        fileSync.append(line);
      }
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    fileSync.append('test failed: $e');
  }
  fileSync.close();
}
