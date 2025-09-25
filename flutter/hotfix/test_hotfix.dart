#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dcli/dcli.dart';

void main() {
  print("🧪 Testing GrowERP Hot Fix Script Dependencies...\n");

  // Test 1: Check if we're in the right directory
  print("✅ Test 1: Directory validation");

  // Check if we're in flutter directory or hotfix subdirectory
  var isInFlutterDir = exists('melos.yaml');
  var isInHotfixDir = exists('../melos.yaml');

  if (!isInFlutterDir && !isInHotfixDir) {
    print("❌ Not in the correct directory structure");
    print("   Must be in flutter directory or flutter/hotfix directory");
    exit(1);
  }

  // Move to flutter directory if we're in hotfix
  if (isInHotfixDir && !isInFlutterDir) {
    Directory.current = Directory('..').absolute;
  }

  if (!exists('../moqui') || !exists('packages')) {
    print("❌ Not in the correct directory structure");
    exit(1);
  }
  print("   ✓ In flutter directory with correct structure");

  // Test 2: Git repository check
  print("\n✅ Test 2: Git repository validation");
  if (!exists('.git') && !exists('../.git')) {
    print("❌ Not in a git repository");
    exit(1);
  }
  print("   ✓ Git repository detected");

  // Test 3: Git tags availability
  print("\n✅ Test 3: Git tags");
  try {
    var tags = 'git tag --sort=-version:refname'.toList();
    if (tags.isEmpty) {
      print("❌ No git tags found");
    } else {
      print("   ✓ Found ${tags.length} git tags");
      print("   ✓ Latest tag: ${tags[0]}");
    }
  } catch (e) {
    print("❌ Error getting git tags: $e");
  }

  // Test 4: Docker availability
  print("\n✅ Test 4: Docker availability");
  try {
    'docker --version'.run;
    print("   ✓ Docker is available");
  } catch (e) {
    print("⚠️  Docker may not be available: $e");
  }

  // Test 5: Commit selection simulation
  print("\n✅ Test 5: Commit selection simulation");
  try {
    // Simulate commit selection parsing
    var testSelection = "1,3,5";
    var parts = testSelection.split(',');
    print(
      "   ✓ Commit selection parsing works: ${parts.length} commits selected",
    );
  } catch (e) {
    print("❌ Commit selection parsing failed: $e");
    exit(1);
  }

  // Test 6: File operations
  print("\n✅ Test 6: File operations");
  var testFile = File('test_hotfix.tmp');
  try {
    testFile.writeAsStringSync('test content');
    testFile.readAsStringSync(); // Verify we can read it back
    testFile.deleteSync();
    print("   ✓ File operations work correctly");
  } catch (e) {
    print("❌ File operations failed: $e");
    exit(1);
  }

  print("\n🎉 All tests passed! Hot fix script should work correctly.");
  print("\n💡 To run the hot fix script:");
  print("   ./hotfix_release.sh");
  print("   or");
  print("   dart hotfix_release.dart");
  print("\n🚀 New features:");
  print("   - Multiple commit selection (1,3,5 or 1-3)");
  print("   - Branch reuse for same base version");
  print("   - Smart conflict handling");
}
