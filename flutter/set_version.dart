#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';

/// Script to set the version of all packages while preserving the '+xx' extension
/// 
/// Usage: dart set_version.dart <new_version>
/// Example: dart set_version.dart 1.10.0
///
/// This script will:
/// - Find all pubspec.yaml files in packages (excluding example directories)
/// - Update the version while preserving any '+xx' build number extension
/// - Does NOT update dependencies (they remain unchanged)

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage: dart set_version.dart <new_version>');
    print('Example: dart set_version.dart 1.10.0');
    exit(1);
  }

  final newVersion = arguments[0];
  
  // Validate version format (basic semver check)
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
  if (!versionRegex.hasMatch(newVersion)) {
    print('Error: Version must be in format x.y.z (e.g., 1.10.0)');
    exit(1);
  }

  print('Setting version to: $newVersion');
  print('Scanning packages...');

  final packagesDir = Directory('packages');
  if (!packagesDir.existsSync()) {
    print('Error: packages directory not found');
    exit(1);
  }

  // Find all pubspec.yaml files, excluding example directories
  final pubspecFiles = await findPubspecFiles(packagesDir);
  
  print('Found ${pubspecFiles.length} packages to update:');
  for (final file in pubspecFiles) {
    final packageName = getPackageName(file);
    print('  - $packageName');
  }

  // Update versions only
  for (final pubspecFile in pubspecFiles) {
    await updatePackageVersion(pubspecFile, newVersion);
  }

  print('\nVersion update completed successfully!');
  print('All packages updated to version: $newVersion');
  print('\nNote: Only version tags were updated, dependencies were not modified.');
  print('\nNext steps:');
  print('1. Manually update dependencies if needed');
  print('2. Run: melos clean && melos bootstrap');
  print('3. Test the changes');
  print('4. Commit the version changes');
}

/// Find all pubspec.yaml files excluding example directories
Future<List<File>> findPubspecFiles(Directory packagesDir) async {
  final pubspecFiles = <File>[];
  
  await for (final entity in packagesDir.list(recursive: false)) {
    if (entity is Directory) {
      final pubspecFile = File('${entity.path}/pubspec.yaml');
      if (await pubspecFile.exists()) {
        // Skip hidden directories and system files
        final dirName = entity.path.split('/').last;
        if (!dirName.startsWith('.')) {
          pubspecFiles.add(pubspecFile);
        }
      }
    }
  }
  
  return pubspecFiles;
}

/// Extract package name from pubspec file path
String getPackageName(File pubspecFile) {
  final pathParts = pubspecFile.path.split('/');
  final packagesIndex = pathParts.lastIndexOf('packages');
  if (packagesIndex != -1 && packagesIndex + 1 < pathParts.length) {
    return pathParts[packagesIndex + 1];
  }
  return 'unknown';
}

/// Update the version in a pubspec.yaml file while preserving build number
Future<void> updatePackageVersion(File pubspecFile, String newVersion) async {
  final content = await pubspecFile.readAsString();
  final lines = content.split('\n');
  
  final updatedLines = <String>[];
  bool versionUpdated = false;
  
  for (final line in lines) {
    if (line.startsWith('version:') && !versionUpdated) {
      final versionMatch = RegExp(r'^version:\s*(.+)$').firstMatch(line.trim());
      if (versionMatch != null) {
        final currentVersion = versionMatch.group(1)!;
        
        // Check if there's a build number (+xx)
        final buildNumberMatch = RegExp(r'\+(\d+)$').firstMatch(currentVersion);
        final buildNumber = buildNumberMatch?.group(1);
        
        final updatedVersion = buildNumber != null 
            ? '$newVersion+$buildNumber'
            : newVersion;
        
        updatedLines.add('version: $updatedVersion');
        versionUpdated = true;
        
        final packageName = getPackageName(pubspecFile);
        print('  Updated $packageName: $currentVersion -> $updatedVersion');
      } else {
        updatedLines.add(line);
      }
    } else {
      updatedLines.add(line);
    }
  }
  
  await pubspecFile.writeAsString(updatedLines.join('\n'));
}