#! /usr/bin/env dcli
// ignore_for_file: dead_code

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:yaml/yaml.dart';

void main() async {
  List<String> apps = [
    'admin',
    'freelance',
    'health',
    'hotel',
    'growerp-moqui'
  ];

  bool test = true;
  final String name = ask('app image name, return for all:', required: false);
  if (name.isNotEmpty && !apps.contains(name)) {
    print("$name is not a valid app, valid apps are $apps");
    exit(1);
  }
  var home = "${env['HOME']}/growerp";

  String currentVersion = '';
  String newVersion = '';
  var appVersion = '';
  String pubspec = '';

  // if not specific app, use the higest current version
  int largestVersionNumber = 0;
  apps.forEach((app) {
    if ((name.isNotEmpty && app == name) || name.isEmpty) {
      if (app == 'growerp-moqui') {
        pubspec = File('$home/moqui/runtime/component/growerp/component.xml')
            .readAsStringSync();
        int start = pubspec.indexOf('name="growerp" version=') + 24;
        appVersion = pubspec.substring(start, pubspec.indexOf('>', start) - 1);
      } else {
        pubspec =
            File('$home/flutter/packages/$app/pubspec.yaml').readAsStringSync();
        appVersion = loadYaml(pubspec)['version'];
      }
      print("current app version: $appVersion");
      var appVersionNumber = int.parse(appVersion.substring(
          appVersion.lastIndexOf('.') + 1, appVersion.indexOf('+')));
      // use the largest
      if (appVersionNumber > largestVersionNumber)
        largestVersionNumber = appVersionNumber;
    }
  });

  largestVersionNumber++;

  apps.forEach((app) {
    if ((name.isNotEmpty && app == name) || name.isEmpty) {
      print(
          "create new version from largest version numer: $largestVersionNumber");
      newVersion = appVersion.substring(0, appVersion.lastIndexOf('.') + 1) +
          largestVersionNumber.toString() +
          appVersion.substring(appVersion.indexOf('+'));
      if (test) {
        if (app == 'growerp-moqui')
          print(
              "=== update componentfile: $home/moqui/runtime/component/growerp/component.xml");
        else
          print(
              "=== update pubspec file : $home/flutter/packages/$app/pubspec.yaml");
      } else {
        // write back new version
        if (app == 'growerp-moqui') {
          '$home/moqui/runtime/component/growerp/component.xml'.replaceFirst(
              'name="growerp" version="$currentVersion',
              'name="growerp" version="$newVersion');
        } else {
          // write back to pubspec file:
          '$home/flutter/packages/$app/pubspec.yaml'.write(pubspec.replaceFirst(
              'version: $currentVersion', 'version: $newVersion'));
        }
      }
      // create image and push to  docker hub
      String dockerImage = 'growerp/$name';
      if (test) {
        print("=== create docker image: $dockerImage");
      } else {
        run('docker build -build-arg DOCKER_TAG=$newVersion -t $dockerImage:latest .',
            workingDirectory: '$home/flutter/packages/$name');
        'docker push $dockerImage:latest';
        'docker tag $dockerImage:latest $dockerImage:$newVersion';
        'docker push $dockerImage:$newVersion';
      }
    }
  });
  // update git
  var commitMessage = "Image created for App ${name.isEmpty ? apps : name} "
      "with tag $newVersion";
  if (test) {
    print("===update git with message: $commitMessage");
  } else {
    run('git add .', workingDirectory: home);
    run('git commit -m \"$commitMessage\"', workingDirectory: home);
    run('git tag $newVersion', workingDirectory: home);
    run('git push origin $newVersion', workingDirectory: home);
  }
}
