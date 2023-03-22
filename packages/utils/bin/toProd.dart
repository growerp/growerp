#! /usr/bin/env dcli

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

void main() {
  const path = 'pubspec.yaml';
  final file = File(path);
  final yamlString = file.readAsStringSync();
  final dynamic yaml = loadYaml(yamlString);
  print(yaml);

  final yamlWriter = YAMLWriter();
  final dynamic yamlDocString = yamlWriter.write({
    'author': 'Franc',
    'database': {
      'driver': 'com.mysql.jdbc.Driver',
      'port': 3306,
      'dbname': 'mydb1',
      'username': 'root',
      'password': ''
    }
  });
  print(yamlDocString);
  File('test.yaml').writeAsString(yamlString);
}
