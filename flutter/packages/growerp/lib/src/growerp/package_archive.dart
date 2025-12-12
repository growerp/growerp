import 'dart:io';

import 'package:archive/archive.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import '../src.dart';

/// Exports a GrowERP package as a zip archive.
///
/// The archive includes both Flutter package and Moqui component.
Future<void> exportPackage(String packageName, String outputPath) async {
  final logger = Logger(filter: MyFilter());

  // Validate package name
  if (!packageName.startsWith('growerp_')) {
    logger.e('Package name must start with "growerp_"');
    exit(1);
  }

  final baseName = packageName.replaceFirst('growerp_', '');

  // Find the root directory (look for melos.yaml)
  String? rootDir = _findProjectRoot();
  if (rootDir == null) {
    logger.e('Could not find project root (melos.yaml not found)');
    exit(1);
  }

  final flutterPackagePath = p.join(
    rootDir,
    'flutter',
    'packages',
    packageName,
  );
  final moquiComponentPath = p.join(
    rootDir,
    'moqui',
    'runtime',
    'component',
    baseName,
  );

  // Check if Flutter package exists
  if (!Directory(flutterPackagePath).existsSync()) {
    logger.e('Flutter package not found: $flutterPackagePath');
    exit(1);
  }

  logger.i('Exporting package: $packageName');
  logger.i('  Flutter package: $flutterPackagePath');

  // Create archive
  final archive = Archive();

  // Add Flutter package files
  await _addDirectoryToArchive(
    archive,
    flutterPackagePath,
    'flutter/$packageName',
    logger,
  );

  // Add Moqui component if it exists
  if (Directory(moquiComponentPath).existsSync()) {
    logger.i('  Moqui component: $moquiComponentPath');
    await _addDirectoryToArchive(
      archive,
      moquiComponentPath,
      'moqui/$baseName',
      logger,
    );
  } else {
    logger.i('  No Moqui component found (optional)');
  }

  // Create output path
  final outputFile = outputPath.endsWith('.zip')
      ? outputPath
      : '$outputPath/$packageName.zip';

  // Ensure output directory exists
  final outputDir = p.dirname(outputFile);
  if (!Directory(outputDir).existsSync()) {
    Directory(outputDir).createSync(recursive: true);
  }

  // Write zip file
  final zipEncoder = ZipEncoder();
  final zipData = zipEncoder.encode(archive);
  if (zipData != null) {
    File(outputFile).writeAsBytesSync(zipData);
    logger.i('✓ Package exported to: $outputFile');
  } else {
    logger.e('Failed to create zip archive');
    exit(1);
  }
}

/// Imports a GrowERP package from a zip archive.
///
/// Extracts to the correct locations and adds package to melos.yaml.
Future<void> importPackage(String archivePath) async {
  final logger = Logger(filter: MyFilter());

  // Validate archive exists
  if (!File(archivePath).existsSync()) {
    logger.e('Archive not found: $archivePath');
    exit(1);
  }

  // Find the root directory
  String? rootDir = _findProjectRoot();
  if (rootDir == null) {
    logger.e('Could not find project root (melos.yaml not found)');
    exit(1);
  }

  logger.i('Importing package from: $archivePath');

  // Read and decode archive
  final bytes = File(archivePath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  // Find package name from archive contents
  String? packageName;
  String? baseName;

  for (final file in archive) {
    if (file.name.startsWith('flutter/growerp_')) {
      final parts = file.name.split('/');
      if (parts.length >= 2) {
        packageName = parts[1];
        baseName = packageName.replaceFirst('growerp_', '');
        break;
      }
    }
  }

  if (packageName == null || baseName == null) {
    logger.e('Invalid archive: could not find package name');
    exit(1);
  }

  logger.i('Package name: $packageName');

  final flutterPackagePath = p.join(
    rootDir,
    'flutter',
    'packages',
    packageName,
  );
  final moquiComponentPath = p.join(
    rootDir,
    'moqui',
    'runtime',
    'component',
    baseName,
  );

  // Check if package already exists
  if (Directory(flutterPackagePath).existsSync()) {
    logger.e('Package already exists: $flutterPackagePath');
    logger.e('Remove it first if you want to re-import');
    exit(1);
  }

  // Extract files
  for (final file in archive) {
    String outputPath;

    if (file.name.startsWith('flutter/')) {
      // Extract to flutter/packages/
      final relativePath = file.name.substring('flutter/'.length);
      outputPath = p.join(rootDir, 'flutter', 'packages', relativePath);
    } else if (file.name.startsWith('moqui/')) {
      // Extract to moqui/runtime/component/
      final relativePath = file.name.substring('moqui/'.length);
      outputPath = p.join(
        rootDir,
        'moqui',
        'runtime',
        'component',
        relativePath,
      );
    } else {
      continue; // Skip unknown paths
    }

    if (file.isFile) {
      final outputFile = File(outputPath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(outputPath).createSync(recursive: true);
    }
  }

  logger.i('  ✓ Extracted Flutter package to: $flutterPackagePath');
  if (Directory(moquiComponentPath).existsSync()) {
    logger.i('  ✓ Extracted Moqui component to: $moquiComponentPath');
  }

  // Add to melos.yaml
  await _addToMelosYaml(rootDir, packageName, logger);

  logger.i('✓ Package imported successfully!');
  logger.i('Run "melos bootstrap" to include the package in the workspace.');
}

/// Adds a directory recursively to the archive.
Future<void> _addDirectoryToArchive(
  Archive archive,
  String directoryPath,
  String archivePath,
  Logger logger,
) async {
  final directory = Directory(directoryPath);

  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      // Skip build artifacts and generated files
      final relativePath = p.relative(entity.path, from: directoryPath);
      if (_shouldSkipFile(relativePath)) {
        continue;
      }

      final archiveFilePath = p.join(archivePath, relativePath);
      final content = entity.readAsBytesSync();

      archive.addFile(ArchiveFile(archiveFilePath, content.length, content));
    }
  }
}

/// Checks if a file should be skipped during export.
bool _shouldSkipFile(String relativePath) {
  final skipPatterns = [
    '.dart_tool',
    'build/',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    '.packages',
    'pubspec.lock',
    '.freezed.dart',
    '.g.dart',
    'generated_plugin_registrant.dart',
    '.idea/',
    '.vscode/',
    'android/.gradle/',
    'ios/Pods/',
    'ios/.symlinks/',
  ];

  for (final pattern in skipPatterns) {
    if (relativePath.contains(pattern)) {
      return true;
    }
  }
  return false;
}

/// Adds the package to melos.yaml.
Future<void> _addToMelosYaml(
  String rootDir,
  String packageName,
  Logger logger,
) async {
  final melosPath = p.join(rootDir, 'flutter', 'melos.yaml');
  final melosFile = File(melosPath);

  if (!melosFile.existsSync()) {
    logger.e('melos.yaml not found: $melosPath');
    return;
  }

  final content = melosFile.readAsStringSync();
  final lines = content.split('\n');

  // Check if package is already in melos.yaml
  final packageEntry = '  - packages/$packageName';
  final exampleEntry = '  - packages/$packageName/example';

  if (content.contains(packageEntry)) {
    logger.i('  Package already in melos.yaml');
    return;
  }

  // Find the packages section and add the new package before "packages/growerp"
  final newLines = <String>[];
  bool added = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Insert before "  - packages/growerp" (the CLI package)
    if (!added && line.trim() == '- packages/growerp') {
      newLines.add(packageEntry);
      newLines.add(exampleEntry);
      added = true;
    }

    newLines.add(line);
  }

  if (!added) {
    // Fallback: add at the end of packages section
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('- packages/') &&
          (i + 1 >= lines.length ||
              !lines[i + 1].trim().startsWith('- packages/'))) {
        newLines.insert(i + 1, exampleEntry);
        newLines.insert(i + 1, packageEntry);
        added = true;
        break;
      }
    }
  }

  if (added) {
    melosFile.writeAsStringSync(newLines.join('\n'));
    logger.i('  ✓ Added package to melos.yaml');
  } else {
    logger.e('  Could not add package to melos.yaml - please add manually');
  }
}

/// Finds the project root directory by looking for melos.yaml.
String? _findProjectRoot() {
  var current = Directory.current;

  // Walk up to find the root
  for (int i = 0; i < 10; i++) {
    // Check for melos.yaml in flutter subdirectory
    final melosPath = p.join(current.path, 'flutter', 'melos.yaml');
    if (File(melosPath).existsSync()) {
      return current.path;
    }

    // Check if current directory has melos.yaml (we might be in flutter/)
    final melosPathHere = p.join(current.path, 'melos.yaml');
    if (File(melosPathHere).existsSync()) {
      return current.parent.path;
    }

    current = current.parent;
  }

  return null;
}
