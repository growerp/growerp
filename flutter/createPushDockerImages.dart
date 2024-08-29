#! /usr/bin/env dcli
// ignore: file_names
// ignore_for_file: dead_code, avoid_print

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
  final String nameList = ask(
      'app image name list separated by comma, return for all:',
      required: false);

  // check names
  List<String> names = [];
  if (nameList.isEmpty) {
    names = apps;
  } else {
    names = nameList.split(',');
    bool error = false;
    for (var name in names) {
      if (!apps.contains(name)) {
        print("$name is not a valid appName");
        error = true;
      }
    }
    if (error == true) {
      print("valid apps are $apps");
      exit(1);
    }
  }
  final String push = ask('Push to growerp.org test system? y/N',
      required: false, defaultValue: 'N');
  String upgradeVersion = 'N';
  if (push.toUpperCase() == 'Y') {
    upgradeVersion = ask('Upgrade the version and save in Git? y/N',
        required: false, defaultValue: 'N');
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
  for (var app in apps) {
    currentVersion = getVersion(app);
    print("=== current app $app version: $currentVersion");
    var appVersionNumber = int.parse(currentVersion.substring(
        currentVersion.lastIndexOf('.') + 1, currentVersion.indexOf('+')));
    // use the largest
    if (appVersionNumber > largestVersionNumber) {
      largestVersionNumber = appVersionNumber;
    }
  }

  print(
      "=== current app(s): $names largest version number: $largestVersionNumber");
  largestVersionNumber++;

  for (var app in apps) {
    if ((names.isNotEmpty && names.contains(app)) || names.isEmpty) {
      // create new version
      currentVersion = getVersion(app);
      newVersion =
          currentVersion.substring(0, currentVersion.lastIndexOf('.') + 1) +
              (largestVersionNumber).toString() +
              currentVersion.substring(currentVersion.indexOf('+'));
      print(
          "=== update versionfile: ${app == 'growerp-moqui' ? '$home/moqui/runtime/component/growerp/component.xml' : '$home/flutter/packages/$app/pubspec.yaml'} old version $currentVersion new version: $newVersion");
      if (upgradeVersion.toUpperCase() == 'Y') {
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
      String dockerImage = 'growerp/$app';
      var dockerTag = newVersion.substring(0, newVersion.indexOf('+'));
      print("=== create docker image: $dockerImage with tag: latest");
      if (!test) {
        if (app == 'growerp-moqui') {
          run('docker build --progress=plain -t $dockerImage:latest . ',
              workingDirectory: '$home/moqui');
        } else {
          run(
              'docker build --file $home/flutter/packages/$app/Dockerfile '
              ' --progress=plain -t $dockerImage:latest . ',
              workingDirectory: '$home/flutter');
        }
        print("=== Image $dockerImage:latest created.");
        if (push.toUpperCase() == 'Y') {
          print(
              "=== pushing docker image: $dockerImage with tag: latest to growerp.org");
          run('docker push $dockerImage:latest');
          if (upgradeVersion.toUpperCase() == 'Y') {
            print("=== create docker image: $dockerImage with tag: $dockerTag");
            run('docker tag $dockerImage:latest $dockerImage:$dockerTag');
            run('docker push $dockerImage:$dockerTag');
          }
        }
      }
    }
  }
  // update git
  var gitTag = newVersion.substring(0, newVersion.indexOf('+'));

  var commitMessage =
      "Image(s) created for App(s) ${(names.isEmpty ? apps : names).join(',')} "
      "with tag $gitTag";
  if (upgradeVersion.toUpperCase() == 'Y') {
    print("=== save version files in git with message: $commitMessage");
    for (var name in names.isEmpty ? apps : names) {
      switch (name) {
        case 'growerp-moqui':
          run('git add $home/moqui/runtime/component/growerp/component.xml',
              workingDirectory: home);
        default:
          run('git add $home/flutter/packages/$name/pubspec.yaml',
              workingDirectory: home);
      }
    }
    run('git commit -m "$commitMessage"', workingDirectory: home);
    run('git tag $gitTag', workingDirectory: home);
    run('git push', workingDirectory: home);
    run('git push origin $gitTag', workingDirectory: home);
  }
}
