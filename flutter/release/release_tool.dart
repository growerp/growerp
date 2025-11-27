#!/usr/bin/env dart
// ignore_for_file: avoid_print, file_names

import 'dart:io';
import 'dart:convert';
import 'package:dcli/dcli.dart';

/// Script to create a production release for GrowERP
/// This script:
/// 1. Validates environment and configuration
/// 2. Allows selection of applications to build
/// 3. Manages version increments (patch, minor, major)
/// 4. Creates Docker images with proper tagging
/// 5. Pushes to Docker Hub and GitHub
/// 6. Updates version files and creates git tags
///
/// Install dcli before running:
///   dart pub global activate dcli
///   dcli install
///

Map<String, dynamic> config = {};

void main() async {
  print("=== GrowERP Production Release Tool ===\n");

  // Load configuration
  await loadConfiguration();

  // Ensure we're in the right directory and git repo
  validateEnvironment();

  // Get user preferences
  var selectedApps = await selectApplications();
  var versionConfig = await getVersionConfiguration();
  var pushConfig = await getPushConfiguration(versionConfig);

  // Determine workspace (local vs repository)
  var workspaceDir = await determineWorkspace(
    pushConfig['pushToGitHub'] ?? false,
  );

  // Calculate version information
  var versionInfo = await calculateVersions(
    selectedApps,
    versionConfig,
    workspaceDir,
  );

  // Display summary and get confirmation
  await displaySummaryAndConfirm(
    selectedApps,
    versionInfo,
    pushConfig,
    workspaceDir,
  );

  // Execute the release process
  await executeRelease(selectedApps, versionInfo, pushConfig, workspaceDir);

  print("\n🎉 Release process completed successfully!");
}

Future<void> loadConfiguration() async {
  var configFile = 'release/release_config.json';

  // Try current directory first, then hotfix directory
  if (!exists(configFile)) {
    configFile = 'release_config.json';
  }

  if (!exists(configFile)) {
    print("Warning: Configuration file not found. Using defaults.");
    config = {
      'defaultApps': [
        'admin',
        'freelance',
        'health',
        'hotel',
        'support',
        'growerp-moqui',
      ],
      'dockerRegistry': 'growerp',
      'defaultPushToDockerHub': true,
      'defaultPushToGitHub': false,
    };
    return;
  }

  try {
    var configContent = File(configFile).readAsStringSync();
    config = jsonDecode(configContent);
    print("✓ Configuration loaded from $configFile");
  } catch (e) {
    print("Error loading configuration: $e");
    exit(1);
  }
}

void validateEnvironment() {
  var isInFlutterDir = exists('melos.yaml');
  var isInReleaseDir = exists('../melos.yaml');

  if (!isInFlutterDir && !isInReleaseDir) {
    print(
      "❌ Error: Please run this script from the flutter directory or flutter/release directory",
    );
    exit(1);
  }

  // If we're in release directory, change to flutter directory
  if (isInReleaseDir && !isInFlutterDir) {
    Directory.current = Directory('..').absolute;
  }

  if (!exists('../moqui') || !exists('packages')) {
    print(
      "❌ Error: Please run this script from the flutter directory of the GrowERP project",
    );
    exit(1);
  }

  // Check if Docker is available
  try {
    run('docker --version');
    print("✓ Docker is available");
  } catch (e) {
    print("❌ Error: Docker is not available. Please install Docker first.");
    exit(1);
  }

  print("✓ Environment validation completed\n");
}

Future<List<String>> selectApplications() async {
  var defaultApps = List<String>.from(config['defaultApps'] ?? []);

  print("📦 Available applications:");
  for (int i = 0; i < defaultApps.length; i++) {
    print("   ${i + 1}. ${defaultApps[i]}");
  }

  var input = ask(
    'Select apps (comma-separated numbers, or press Enter for all):',
    required: false,
  );

  if (input.isEmpty) {
    print("Selected: All applications");
    return defaultApps;
  }

  try {
    var indices = input.split(',').map((s) => int.parse(s.trim()) - 1).toList();
    var selectedApps = indices.map((i) => defaultApps[i]).toList();
    print("Selected: ${selectedApps.join(', ')}");
    return selectedApps;
  } catch (e) {
    print("❌ Invalid selection. Please use comma-separated numbers.");
    exit(1);
  }
}

Future<Map<String, bool>> getVersionConfiguration() async {
  var upgradePatch =
      ask(
        'Upgrade patch version (recommended for releases)? (Y/n)',
        defaultValue: 'Y',
      ).toUpperCase() ==
      'Y';

  var upgradeMinor = false;
  var upgradeMajor = false;

  if (upgradePatch) {
    upgradeMinor =
        ask(
          'Upgrade minor version (for new features)? (y/N)',
          defaultValue: 'N',
        ).toUpperCase() ==
        'Y';

    if (upgradeMinor) {
      upgradeMajor =
          ask(
            'Upgrade major version (for breaking changes)? (y/N)',
            defaultValue: 'N',
          ).toUpperCase() ==
          'Y';
    }
  }

  return {'patch': upgradePatch, 'minor': upgradeMinor, 'major': upgradeMajor};
}

Future<Map<String, bool>> getPushConfiguration(
  Map<String, bool> versionConfig,
) async {
  var pushToDockerHub =
      ask(
        'Push to Docker Hub? (Y/n)',
        defaultValue: config['defaultPushToDockerHub'] ? 'Y' : 'N',
      ).toUpperCase() ==
      'Y';

  // Always push to GitHub when building Docker images
  // This ensures Docker builds from the repository with versioned code
  var pushToGitHub = pushToDockerHub;

  if (versionConfig['patch'] == false) {
    pushToGitHub = false;
    print(
      "   Note: Not pushing to GitHub because patch version is not incremented.",
    );
  }

  return {'pushToDockerHub': pushToDockerHub, 'pushToGitHub': pushToGitHub};
}

Future<String> determineWorkspace(bool pushToGitHub) async {
  // Always use temp directory for release builds to ensure clean state
  var tempDir = config['tempWorkspaceDir'] ?? '/tmp/growerp';
  print("📁 Setting up repository workspace at: $tempDir");

  if (exists(tempDir)) {
    print("   Cleaning existing repository...");
    run('rm -rf "$tempDir"');
  }

  print("   Cloning fresh repository...");
  var repoUrl = config['repositoryUrl'] ?? 'git@github.com:growerp/growerp.git';
  var branch = config['defaultBranch'] ?? 'master';
  run('git clone -b $branch "$repoUrl" "$tempDir"');

  return tempDir;
}

Future<Map<String, dynamic>> calculateVersions(
  List<String> selectedApps,
  Map<String, bool> versionConfig,
  String workspaceDir,
) async {
  print("\n📊 Calculating version information...");

  // Get current versions for all apps
  var currentVersions = <String, String>{};
  var largestMajor = 0, largestMinor = 0, largestPatch = 0;

  for (var app in selectedApps) {
    var version = getVersion(app, workspaceDir);
    currentVersions[app] = version;
    print("   $app: $version");

    // Parse version components
    var versionParts = parseVersion(version);
    var major = versionParts['major'] ?? 0;
    var minor = versionParts['minor'] ?? 0;
    var patch = versionParts['patch'] ?? 0;
    if (major > largestMajor) largestMajor = major;
    if (minor > largestMinor) largestMinor = minor;
    if (patch > largestPatch) largestPatch = patch;
  }

  // Calculate new version
  if (versionConfig['patch'] == true) {
    largestPatch++;
    if (versionConfig['minor'] == true) {
      largestPatch = 0;
      largestMinor++;
      if (versionConfig['major'] == true) {
        largestMinor = 0;
        largestMajor++;
      }
    }
  }

  var newVersionBase = "$largestMajor.$largestMinor.$largestPatch";
  print("   Next version: $newVersionBase");

  return {
    'current': currentVersions,
    'newBase': newVersionBase,
    'major': largestMajor,
    'minor': largestMinor,
    'patch': largestPatch,
  };
}

String getVersion(String appName, String workspaceDir) {
  if (appName == 'growerp-moqui') {
    // For moqui, determine the correct path based on workspace structure
    var componentFile = '';
    if (workspaceDir.endsWith('/flutter')) {
      // We're in the flutter directory, go up one level to find moqui
      componentFile =
          '$workspaceDir/../moqui/runtime/component/growerp/component.xml';
    } else {
      // We're in the root workspace directory
      componentFile =
          '$workspaceDir/moqui/runtime/component/growerp/component.xml';
    }
    var content = File(componentFile).readAsStringSync();
    var start = content.indexOf('name="growerp" version=') + 24;
    return content.substring(start, content.indexOf('>', start) - 1);
  } else {
    // For flutter apps, determine the correct path based on workspace structure
    var pubspecFile = '';
    if (workspaceDir.endsWith('/flutter')) {
      // We're already in the flutter directory
      pubspecFile = '$workspaceDir/packages/$appName/pubspec.yaml';
    } else {
      // We're in the root workspace directory
      pubspecFile = '$workspaceDir/flutter/packages/$appName/pubspec.yaml';
    }
    var content = File(pubspecFile).readAsStringSync();
    var lines = content.split('\n');
    for (var line in lines) {
      if (line.startsWith('version:')) {
        return line.split(':')[1].trim();
      }
    }
    throw Exception('Could not find version in $pubspecFile');
  }
}

Map<String, int> parseVersion(String version) {
  var versionOnly = version.contains('+') ? version.split('+')[0] : version;
  var parts = versionOnly.split('.');
  return {
    'major': int.parse(parts[0]),
    'minor': int.parse(parts[1]),
    'patch': int.parse(parts[2]),
  };
}

Future<void> displaySummaryAndConfirm(
  List<String> selectedApps,
  Map<String, dynamic> versionInfo,
  Map<String, bool> pushConfig,
  String workspaceDir,
) async {
  print("\n📋 Release Summary:");
  print("   Applications: ${selectedApps.join(', ')}");
  print("   New version: ${versionInfo['newBase']}");
  print(
    "   Workspace: ${workspaceDir == Directory.current.path ? 'Local' : 'Repository'}",
  );
  print(
    "   Push to Docker Hub: ${pushConfig['pushToDockerHub'] == true ? 'Yes' : 'No'}",
  );
  print(
    "   Push to GitHub: ${pushConfig['pushToGitHub'] == true ? 'Yes' : 'No'}",
  );

  var confirm = ask('\nProceed with release? (y/N)', defaultValue: 'N');
  if (confirm.toUpperCase() != 'Y') {
    print("Release cancelled.");
    exit(0);
  }
}

Future<void> executeRelease(
  List<String> selectedApps,
  Map<String, dynamic> versionInfo,
  Map<String, bool> pushConfig,
  String workspaceDir,
) async {
  print("\n🚀 Starting release process...\n");

  var newVersions = <String, String>{};

  // Step 1: Update version files in workspace
  print("� Step 1: Updating version files in workspace...\n");
  for (var app in selectedApps) {
    var currentVersion = versionInfo['current'][app];
    var buildSuffix = currentVersion.contains('+')
        ? currentVersion.substring(currentVersion.indexOf('+'))
        : '+1';
    var newVersion = "${versionInfo['newBase']}$buildSuffix";
    newVersions[app] = newVersion;

    await updateVersionFile(app, currentVersion, newVersion, workspaceDir);
  }

  // Step 2: Commit, tag, and push to GitHub
  if (pushConfig['pushToGitHub'] == true) {
    print("\n📤 Step 2: Committing and pushing to GitHub...\n");
    await commitAndTag(
      selectedApps,
      newVersions,
      versionInfo['newBase'],
      workspaceDir,
    );

    // Wait a moment for GitHub to process the push
    print("   Waiting for GitHub to process push...");
    sleep(3);
  }

  // Step 3: Build Docker images from repository
  print("\n🐳 Step 3: Building Docker images from repository...\n");
  var imageIds = <String, String>{};

  for (var app in selectedApps) {
    print("📦 Building $app...");
    var newVersion = newVersions[app]!;

    // Build Docker image - will clone from repository
    var imageId = await buildDockerImage(app, workspaceDir, newVersion);
    imageIds[app] = imageId;

    // Push to Docker Hub
    if (pushConfig['pushToDockerHub'] == true) {
      await pushDockerImage(app, versionInfo['newBase']);
    }

    print("✓ $app completed\n");
  }

  // Display final summary
  displayFinalSummary(selectedApps, imageIds, versionInfo['newBase']);
}

Future<void> updateVersionFile(
  String app,
  String currentVersion,
  String newVersion,
  String workspaceDir,
) async {
  print("   Updating version file: $currentVersion → $newVersion");

  if (app == 'growerp-moqui') {
    // For moqui, determine the correct path based on workspace structure
    var file = '';
    if (workspaceDir.endsWith('/flutter')) {
      // We're in the flutter directory, go up one level to find moqui
      file = '$workspaceDir/../moqui/runtime/component/growerp/component.xml';
    } else {
      // We're in the root workspace directory
      file = '$workspaceDir/moqui/runtime/component/growerp/component.xml';
    }
    replace(
      file,
      'name="growerp" version="$currentVersion',
      'name="growerp" version="$newVersion',
    );
  } else {
    // For flutter apps, determine the correct path based on workspace structure
    var file = '';
    if (workspaceDir.endsWith('/flutter')) {
      // We're already in the flutter directory
      file = '$workspaceDir/packages/$app/pubspec.yaml';
    } else {
      // We're in the root workspace directory
      file = '$workspaceDir/flutter/packages/$app/pubspec.yaml';
    }
    replace(file, 'version: $currentVersion', 'version: $newVersion');
  }
}

Future<String> buildDockerImage(
  String app,
  String workspaceDir,
  String version,
) async {
  var dockerImage = '${config['dockerRegistry']}/$app';
  print("   Building Docker image: $dockerImage:latest with version $version");

  try {
    if (app == 'growerp-moqui') {
      // For moqui, determine the correct path based on workspace structure
      var moquiDir = '';
      if (workspaceDir.endsWith('/flutter')) {
        // We're in the flutter directory, go up one level to find moqui
        moquiDir = '$workspaceDir/../moqui';
      } else {
        // We're in the root workspace directory
        moquiDir = '$workspaceDir/moqui';
      }
      run(
        'docker build --build-arg DOCKER_TAG=$version --progress=plain -t $dockerImage:latest . --no-cache',
        workingDirectory: moquiDir,
      );
    } else {
      // For flutter apps, determine the correct paths based on workspace structure
      var dockerfilePath = '';
      var buildContext = '';
      if (workspaceDir.endsWith('/flutter')) {
        // We're already in the flutter directory
        dockerfilePath = '$workspaceDir/packages/$app/Dockerfile';
        buildContext = workspaceDir;
      } else {
        // We're in the root workspace directory
        dockerfilePath = '$workspaceDir/flutter/packages/$app/Dockerfile';
        buildContext = '$workspaceDir/flutter';
      }
      run(
        'docker build --file $dockerfilePath --build-arg DOCKER_TAG=$version '
        '--progress=plain -t $dockerImage:latest . --no-cache',
        workingDirectory: buildContext,
      );
    }

    var imageId = 'docker images -q $dockerImage:latest'.firstLine ?? '?';
    print("   ✓ Image built successfully: $imageId");
    return imageId;
  } catch (e) {
    print("   ❌ Failed to build Docker image: $e");
    exit(1);
  }
}

Future<void> pushDockerImage(String app, String version) async {
  var dockerImage = '${config['dockerRegistry']}/$app';

  print("   Pushing to Docker Hub: $dockerImage:latest");
  try {
    run('docker push $dockerImage:latest');
    print("   ✓ Latest image pushed successfully");

    print("   Tagging and pushing version: $dockerImage:$version");
    run('docker tag $dockerImage:latest $dockerImage:$version');
    run('docker push $dockerImage:$version');
    print("   ✓ Version image pushed successfully");
  } catch (e) {
    print("   ❌ Failed to push Docker image: $e");
    exit(1);
  }
}

Future<void> commitAndTag(
  List<String> selectedApps,
  Map<String, String> newVersions,
  String gitTag,
  String workspaceDir,
) async {
  print("📝 Committing version changes and creating git tag...");

  try {
    // Determine git working directory - should be the root workspace
    var gitWorkingDir = workspaceDir;
    if (workspaceDir.endsWith('/flutter')) {
      // If we're in the flutter directory, go up one level for git operations
      gitWorkingDir = '$workspaceDir/..';
    }

    // Add version files to git
    for (var app in selectedApps) {
      if (app == 'growerp-moqui') {
        run(
          'git add moqui/runtime/component/growerp/component.xml',
          workingDirectory: gitWorkingDir,
        );
      } else {
        run(
          'git add flutter/packages/$app/pubspec.yaml',
          workingDirectory: gitWorkingDir,
        );
      }
    }

    // Create commit message
    var appVersions = selectedApps
        .map((app) => '$app:${newVersions[app]}')
        .join(', ');
    var commitMessage = 'build: Release $gitTag - $appVersions';

    // Commit and tag
    run('git commit -m "$commitMessage"', workingDirectory: gitWorkingDir);
    run('git tag $gitTag', workingDirectory: gitWorkingDir);
    run('git push', workingDirectory: gitWorkingDir);
    run('git push origin $gitTag', workingDirectory: gitWorkingDir);

    print("   ✓ Git tag $gitTag created and pushed");
  } catch (e) {
    print("   ❌ Failed to commit and tag: $e");
    exit(1);
  }
}

void displayFinalSummary(
  List<String> selectedApps,
  Map<String, String> imageIds,
  String version,
) {
  print("\n🎯 Release Summary:");
  print("   Version: $version");
  print("   Applications:");
  for (var app in selectedApps) {
    print("     • $app (${imageIds[app]})");
  }
  print("\n💡 Next steps:");
  print("   • Update production docker-compose.yaml with version $version");
  print("   • Deploy to production: docker-compose up -d");
  print("   • Monitor application startup and logs");
}
