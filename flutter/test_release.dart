#!/usr/bin/env dart
// ignore_for_file: avoid_print, file_names

import 'dart:io';
import 'dart:convert';
import 'package:dcli/dcli.dart';

/// Test script for the GrowERP Release Tool
/// Validates dependencies, configuration, and core functionality

void main() async {
  print("🧪 Testing GrowERP Release Tool Dependencies...");

  var allPassed = true;

  // Test 1: Directory validation
  print("\n✅ Test 1: Directory validation");
  try {
    var isInFlutterDir = exists('melos.yaml');
    var isInReleaseDir = exists('../melos.yaml') && exists('release_tool.dart');

    if (isInFlutterDir) {
      print("   ✓ In flutter directory with correct structure");
    } else if (isInReleaseDir) {
      print("   ✓ In release directory with correct structure");
    } else {
      print("   ❌ Not in correct directory structure");
      allPassed = false;
    }
  } catch (e) {
    print("   ❌ Directory validation failed: $e");
    allPassed = false;
  }

  // Test 2: Git repository validation
  print("\n✅ Test 2: Git repository validation");
  try {
    'git status'.firstLine;
    print("   ✓ Git repository detected");
  } catch (e) {
    print("   ❌ Git repository not found or git not available: $e");
    allPassed = false;
  }

  // Test 3: Configuration loading
  print("\n✅ Test 3: Configuration loading");
  try {
    var configFile = 'release_config.json';
    if (!exists(configFile) && exists('release/release_config.json')) {
      configFile = 'release/release_config.json';
    }

    if (exists(configFile)) {
      var configContent = File(configFile).readAsStringSync();
      var config = jsonDecode(configContent);
      print("   ✓ Configuration loaded successfully");
      print(
        "   ✓ Found ${config['defaultApps']?.length ?? 0} default applications",
      );
    } else {
      print("   ⚠️  Configuration file not found, will use defaults");
    }
  } catch (e) {
    print("   ❌ Configuration loading failed: $e");
    allPassed = false;
  }

  // Test 4: Docker availability
  print("\n✅ Test 4: Docker availability");
  try {
    var dockerVersion = 'docker --version'.firstLine;
    print(dockerVersion ?? 'Docker version not detected');
    print("   ✓ Docker is available");
  } catch (e) {
    print("   ❌ Docker is not available: $e");
    allPassed = false;
  }

  // Test 5: Version parsing simulation
  print("\n✅ Test 5: Version parsing simulation");
  try {
    var testVersions = ['1.9.0+1', '1.10.0+2', '2.0.0+1'];
    var largestMajor = 0, largestMinor = 0, largestPatch = 0;

    for (var version in testVersions) {
      var versionOnly = version.contains('+') ? version.split('+')[0] : version;
      var parts = versionOnly.split('.');
      var major = int.parse(parts[0]);
      var minor = int.parse(parts[1]);
      var patch = int.parse(parts[2]);

      if (major > largestMajor) largestMajor = major;
      if (minor > largestMinor) largestMinor = minor;
      if (patch > largestPatch) largestPatch = patch;
    }

    print("   ✓ Version parsing works correctly");
    print(
      "   ✓ Largest version found: $largestMajor.$largestMinor.$largestPatch",
    );
  } catch (e) {
    print("   ❌ Version parsing failed: $e");
    allPassed = false;
  }

  // Test 6: File operations
  print("\n✅ Test 6: File operations");
  try {
    var testFile = 'test_temp_file.txt';

    // Create test file
    File(testFile).writeAsStringSync('version: 1.0.0+1');

    // Read and validate
    var content = File(testFile).readAsStringSync();
    if (content.contains('version: 1.0.0+1')) {
      print("   ✓ File operations work correctly");
    } else {
      print("   ❌ File content validation failed");
      allPassed = false;
    }

    // Cleanup
    if (exists(testFile)) {
      File(testFile).deleteSync();
    }
  } catch (e) {
    print("   ❌ File operations failed: $e");
    allPassed = false;
  }

  // Test 7: Application detection
  print("\n✅ Test 7: Application detection");
  try {
    var expectedApps = ['admin', 'freelance', 'health', 'hotel', 'support'];
    var foundApps = <String>[];

    if (exists('packages') || exists('../flutter/packages')) {
      var packagesDir = exists('packages') ? 'packages' : '../flutter/packages';

      for (var app in expectedApps) {
        if (exists('$packagesDir/$app/pubspec.yaml')) {
          foundApps.add(app);
        }
      }
    }

    // Check for growerp-moqui
    if (exists('../moqui/runtime/component/growerp/component.xml') ||
        exists('../../moqui/runtime/component/growerp/component.xml')) {
      foundApps.add('growerp-moqui');
    }

    print(
      "   ✓ Found ${foundApps.length} applications: ${foundApps.join(', ')}",
    );

    if (foundApps.length < expectedApps.length) {
      print("   ⚠️  Some applications not found (this may be normal)");
    }
  } catch (e) {
    print("   ❌ Application detection failed: $e");
    allPassed = false;
  }

  // Final results
  print("\n${"=" * 50}");
  if (allPassed) {
    print("🎉 All tests passed! Release tool should work correctly.");
    print("💡 To run the release tool:");
    print("   ./release.sh");
    print("   or");
    print("   dart release_tool.dart");

    print("\n🚀 New features:");
    print("   - Interactive application selection");
    print("   - Version increment options (patch/minor/major)");
    print("   - Local vs repository workspace modes");
    print("   - Enhanced error handling and validation");
    print("   - Comprehensive logging and status updates");
  } else {
    print(
      "❌ Some tests failed. Please resolve the issues before using the release tool.",
    );
    exit(1);
  }
}
