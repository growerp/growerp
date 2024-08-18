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

  bool test = false;
  final String name = ask('app image name, return for all:', required: false);
  if (name.isNotEmpty && !apps.contains(name)) {
    print("$name is not a valid app, valid apps are $apps");
    exit(1);
  }
  var home = "${env['HOME']}/growerp";

  String getVersion(String appName) {
    var pubspec = '';
    if (appName == 'growerp-moqui') {
      pubspec = File('$home/moqui/runtime/component/growerp/component.xml')
          .readAsStringSync();
      int start = pubspec.indexOf('name="growerp" version=') + 24;
      return pubspec.substring(start, pubspec.indexOf('>', start) - 1);
    } else {
      pubspec = File('$home/flutter/packages/$appName/pubspec.yaml')
          .readAsStringSync();
      return loadYaml(pubspec)['version'];
    }
  }

  String newVersion = '';
  var currentVersion = '';

  // always use the higest current version of all apps (all in a monorep)
  int largestVersionNumber = 0;
  apps.forEach((app) {
    currentVersion = getVersion(app);
    print("current app $app version: $currentVersion");
    var appVersionNumber = int.parse(currentVersion.substring(
        currentVersion.lastIndexOf('.') + 1, currentVersion.indexOf('+')));
    // use the largest
    if (appVersionNumber > largestVersionNumber)
      largestVersionNumber = appVersionNumber;
  });

  print("current app: $name largest version number: $largestVersionNumber");

  apps.forEach((app) {
    if ((name.isNotEmpty && app == name) || name.isEmpty) {
      // create new version
      currentVersion = getVersion(app);
      newVersion =
          currentVersion.substring(0, currentVersion.lastIndexOf('.') + 1) +
              (++largestVersionNumber).toString() +
              currentVersion.substring(currentVersion.indexOf('+'));
      print(
          "update versionfile: ${app == 'growerp-moqui' ? '$home/moqui/runtime/component/growerp/component.xml' : '$home/flutter/packages/$app/pubspec.yaml'} old version $currentVersion new version: $newVersion");
      if (!test) {
        // write back new version
        if (app == 'growerp-moqui') {
          replace(
              '$home/moqui/runtime/component/growerp/component.xml',
              'name="growerp" version="$currentVersion',
              'name="growerp" version="$newVersion');
        } else {
          // write back to pubspec file:
          replace('$home/flutter/packages/$app/pubspec.yaml',
              'version: $currentVersion', 'version: $newVersion');
        }
      }
      // create image and push to  docker hub
      String dockerImage = 'growerp/$name';
      var dockerTag = newVersion.substring(0, newVersion.indexOf('+'));
      print("=== create docker image: $dockerImage with tag: $dockerTag");
      if (!test) {
        if (app == 'growerp-moqui') {
          run('docker build -t $dockerImage:latest .',
              workingDirectory: '$home/moqui');
        } else {
          run(
              'docker build --file $home/flutter/packages/$name/Dockerfile '
              '-t $dockerImage:latest .',
              workingDirectory: '$home/flutter');
        }
        run('docker push $dockerImage:latest');
        run('docker tag $dockerImage:latest $dockerImage:$dockerTag');
        run('docker push $dockerImage:$dockerTag');
      }
    }
  });
  // update git
  var gitTag = newVersion.substring(0, newVersion.indexOf('+'));
  var commitMessage = "Image created for App ${name.isEmpty ? apps : name} "
      "with tag $gitTag";
  print("update git with message: $commitMessage");
  if (!test) {
    run('git add .', workingDirectory: home);
    run('git commit -m \"$commitMessage\"', workingDirectory: home);
    run('git tag $gitTag', workingDirectory: home);
    run('git push', workingDirectory: home);
    run('git push origin $gitTag', workingDirectory: home);
  }
}
