// ignore_for_file: avoid_dynamic_calls
import 'package:dcli/dcli.dart';
import 'package:pub_api_client/pub_api_client.dart';

import '../models/models.dart';
import 'functions.dart';

List<GrowerpPackage> getPackageList(String packageDir) {
  final componentList = <GrowerpPackage>[];
  final client = PubClient();

  find('pubspec.yaml', types: [Find.file], workingDirectory: growerpPath)
      .forEach((file) async {
    if (file.contains('flutterDevelopment/packages/growerp') &&
        !file.contains('build') &&
        !file.contains('example')) {
      final nameEnd = file.indexOf('/pubspec.yaml');
      componentList
          .add(await getGrowerpPackageInfo(client, file.substring(0, nameEnd)));
    }
  });
  // move growerp_core to the beginning of the list
  if (componentList.isNotEmpty) {
    final coreIndex = componentList.indexWhere((e) => e.name == 'growerp_core');
    final temp = componentList.first;
    componentList.first = componentList[coreIndex];
    componentList[coreIndex] = temp;
  } else {
    logger.e('no packages found?');
  }
  return componentList;
}
