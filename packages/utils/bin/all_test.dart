#! /usr/bin/env dcli

// ignore: prefer_relative_imports
import 'dart:io';

import 'package:dcli/dcli.dart';

void main(List<String> args) {
  const logFile = 'all_test.log';
  'rm $logFile'.toList(nothrow: true);
  final fileSync = FileSync(logFile);
  find('all_test.dart', types: [Find.file], workingDirectory: '..')
      .forEach((file) {
    if (file.contains('/growerp_')) {
      final wdEnd = file.indexOf('/integration_test/all_test.dart');
      final nameEnd = file.indexOf('/example/integration_test/all_test.dart');
      final nameStart = file.substring(0, nameEnd).lastIndexOf('/') + 1;
      print('Processing: ${file.substring(nameStart, nameEnd)}');
      fileSync.append(
          '=========processing ${file.substring(nameStart, nameEnd)}=========');
      final results = 'flutter test $file'
          .toList(workingDirectory: file.substring(0, wdEnd), nothrow: true);
      for (final line in results) {
        if (line.contains('[E]') || line.contains('skipped')) {
          fileSync.append(line);
        }
      }
    }
  });
  fileSync.close();
  'cat $logFile'.run;
}
