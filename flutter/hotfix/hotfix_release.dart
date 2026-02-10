#!/usr/bin/env dart
// ignore_for_file: avoid_print, file_names

import 'dart:io';
import 'package:dcli/dcli.dart';

/// Script to create a hot fix release for production
/// This script:
/// 1. Creates or reuses a branch from a selected production tag
/// 2. Applies selected commit(s) from master (supports multiple commits)
/// 3. Creates a Docker build for the new tag (without latest tag)
/// 4. Pushes to hub.docker.com
/// 5. Pushes the branch and updates GitHub
///
/// Install dcli before running:
///   dart pub global activate dcli
///   dcli install
///

void main() async {
  List<String> apps = [
    'admin',
    'freelance',
    'health',
    'hotel',
    'support',
    'growerp-moqui',
  ];

  print("=== GrowERP Hot Fix Release Tool ===\n");

  // Ensure we're in the right directory and git repo
  var isInFlutterDir = exists('melos.yaml') || exists('pubspec.yaml');
  var isInHotfixDir = exists('../melos.yaml') || exists('../pubspec.yaml');

  if (!isInFlutterDir && !isInHotfixDir) {
    print(
      "Error: Please run this script from the flutter directory or flutter/hotfix directory",
    );
    exit(1);
  }

  // If we're in hotfix directory, change to flutter directory
  if (isInHotfixDir && !isInFlutterDir) {
    Directory.current = Directory('..').absolute;
  }

  if (!exists('../moqui') || !exists('packages')) {
    print(
      "Error: Please run this script from the flutter directory of the GrowERP project",
    );
    exit(1);
  }

  if (!exists('.git') && !exists('../.git')) {
    print("Error: Not in a git repository");
    exit(1);
  }

  // Get available tags
  print("Fetching available production tags...");
  var tags = 'git tag --sort=-version:refname'.toList();
  if (tags.isEmpty) {
    print("No tags found in repository!");
    exit(1);
  }

  // Display latest tags and get base tag selection
  print("\nAvailable production tags (latest 10):");
  for (int i = 0; i < (tags.length > 10 ? 10 : tags.length); i++) {
    print("  ${i + 1}. ${tags[i]}");
  }

  String baseTag = ask(
    '\nSelect base production tag [default: ${tags[0]}]:',
    required: false,
    defaultValue: tags[0],
  );

  if (!tags.contains(baseTag)) {
    print("Invalid tag: $baseTag");
    exit(1);
  }

  // Get commits since the base tag
  print("\nFetching commits since $baseTag...");
  var commits = 'git log --oneline $baseTag..master'.toList();
  if (commits.isEmpty) {
    print("No new commits found since $baseTag on master branch!");
    exit(1);
  }

  // Display recent commits and get selection
  print("\nRecent commits on master since $baseTag:");
  for (int i = 0; i < (commits.length > 15 ? 15 : commits.length); i++) {
    print("  ${i + 1}. ${commits[i]}");
  }

  String selectedCommits = ask(
    '\nSelect commit(s) to apply:\n'
    '  - Single commit: commit-hash or number (e.g., "a1b2c3d" or "1")\n'
    '  - Multiple commits: comma-separated (e.g., "1,3,5" or "a1b2c3d,e4f5g6h")\n'
    '  - Range: dash-separated numbers (e.g., "1-3" for commits 1,2,3)\n'
    '  [default: latest (${commits[0].split(' ')[0]})]:',
    required: false,
    defaultValue: commits[0].split(' ')[0],
  );

  // Parse and validate commit selection
  List<String> commitHashes = [];
  var selection = selectedCommits.trim();

  if (selection.contains('-') && RegExp(r'^\d+-\d+$').hasMatch(selection)) {
    // Handle range selection (e.g., "1-3")
    var parts = selection.split('-');
    int start = int.parse(parts[0]);
    int end = int.parse(parts[1]);

    if (start < 1 || end > commits.length || start > end) {
      print("Invalid range: $selection (must be between 1-${commits.length})");
      exit(1);
    }

    for (int i = start; i <= end; i++) {
      commitHashes.add(commits[i - 1].split(' ')[0]);
    }
  } else if (selection.contains(',')) {
    // Handle multiple commits (e.g., "1,3,5" or "a1b2c3d,e4f5g6h")
    var selections = selection.split(',');
    for (var sel in selections) {
      sel = sel.trim();
      if (RegExp(r'^\d+$').hasMatch(sel)) {
        // Number selection
        int index = int.parse(sel);
        if (index < 1 || index > commits.length) {
          print(
            "Invalid commit number: $sel (must be between 1-${commits.length})",
          );
          exit(1);
        }
        commitHashes.add(commits[index - 1].split(' ')[0]);
      } else if (RegExp(r'^[a-f0-9]{7,40}$').hasMatch(sel)) {
        // Hash selection
        commitHashes.add(sel);
      } else {
        // Try to find partial match
        var matchingCommits = commits.where((c) => c.startsWith(sel)).toList();
        if (matchingCommits.isEmpty) {
          print("Invalid commit: $sel");
          exit(1);
        }
        commitHashes.add(matchingCommits.first.split(' ')[0]);
      }
    }
  } else {
    // Handle single commit
    if (RegExp(r'^\d+$').hasMatch(selection)) {
      // Number selection
      int index = int.parse(selection);
      if (index < 1 || index > commits.length) {
        print(
          "Invalid commit number: $selection (must be between 1-${commits.length})",
        );
        exit(1);
      }
      commitHashes.add(commits[index - 1].split(' ')[0]);
    } else if (RegExp(r'^[a-f0-9]{7,40}$').hasMatch(selection)) {
      // Hash selection
      commitHashes.add(selection);
    } else {
      // Try to find partial match
      var matchingCommits = commits
          .where((c) => c.startsWith(selection))
          .toList();
      if (matchingCommits.isEmpty) {
        print("Invalid commit: $selection");
        exit(1);
      }
      commitHashes.add(matchingCommits.first.split(' ')[0]);
    }
  }

  // Remove duplicates while preserving order
  commitHashes = commitHashes.toSet().toList();

  print("\nSelected commits to apply (in selection order):");
  for (var hash in commitHashes) {
    var commitInfo = commits.firstWhere(
      (c) => c.startsWith(hash),
      orElse: () => hash,
    );
    print("  - $commitInfo");
  }

  print(
    "\nNote: Commits will be applied in chronological order (oldest to newest) to reduce conflicts.",
  );

  // Generate new tag name (remove 'v' prefix if present)
  var baseVersion = baseTag.startsWith('v') ? baseTag.substring(1) : baseTag;
  var parts = baseVersion.split('.');
  if (parts.length < 3) {
    print(
      "Invalid base tag format: $baseTag (expected format: 1.2.3 or v1.2.3)",
    );
    exit(1);
  }

  var newPatch = int.parse(parts[2]) + 1;
  var suggestedTag = "${parts[0]}.${parts[1]}.$newPatch";

  // Branch name based on base version for reusability
  var branchName = "hotfix-$baseVersion";

  String newTag = ask(
    '\nEnter new tag name [default: $suggestedTag]:',
    required: false,
    defaultValue: suggestedTag,
  );

  // Validate new tag format (no 'v' prefix)
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(newTag)) {
    print("Invalid tag format: $newTag (expected format: 1.2.3)");
    exit(1);
  }

  // Check if tag already exists
  if (tags.contains(newTag)) {
    print("Tag $newTag already exists!");
    exit(1);
  }

  // Select apps to build
  String nameList = ask(
    '\nApp image name list (comma separated) [default: all apps]:',
    required: false,
  );

  Map<String, String> selectedApps = {};
  if (nameList.isEmpty) {
    for (final app in apps) {
      selectedApps[app] = '';
    }
  } else {
    bool error = false;
    for (var name in nameList.split(',')) {
      name = name.trim();
      if (!apps.contains(name)) {
        print("$name is not a valid app name");
        error = true;
      } else {
        selectedApps[name] = '';
      }
    }
    if (error) {
      print("Valid apps are: $apps");
      exit(1);
    }
  }

  // Confirm push to Docker Hub
  String pushToDockerHub = ask(
    '\nPush to hub.docker.com? [Y/n]:',
    required: false,
    defaultValue: 'Y',
  );

  // Show summary and confirm
  print("\n=== Hot Fix Summary ===");
  print("Base tag: $baseTag");
  print("Commits to apply: ${commitHashes.join(', ')}");
  print("New tag: $newTag");
  print("Apps to build: ${selectedApps.keys.join(', ')}");
  print("Push to Docker Hub: ${pushToDockerHub.toUpperCase()}");
  print("Branch name: $branchName");

  String confirm = ask(
    '\nProceed with hot fix? [Y/n]:',
    required: false,
    defaultValue: 'Y',
  );

  if (confirm.toUpperCase() != 'Y') {
    print("Hot fix cancelled.");
    exit(0);
  }

  var currentDir = Directory.current.path;

  try {
    // Step 1: Create or checkout hotfix branch
    print("\n=== Step 1: Managing branch $branchName ===");
    run('git fetch --all');

    // Check if branch already exists locally
    var existingBranches = 'git branch --list $branchName'.toList();
    if (existingBranches.isNotEmpty) {
      print("Branch $branchName already exists locally.");
      String reuseBranch = ask(
        'Reuse existing branch? [Y/n]:',
        required: false,
        defaultValue: 'Y',
      );
      if (reuseBranch.toUpperCase() == 'Y') {
        run('git checkout $branchName');
        print("✓ Switched to existing branch $branchName");
      } else {
        String deleteBranch = ask(
          'Delete existing branch and create new? [y/N]:',
          required: false,
          defaultValue: 'N',
        );
        if (deleteBranch.toUpperCase() != 'Y') {
          print("Hot fix cancelled.");
          exit(0);
        }
        run('git branch -D $branchName');
        run('git checkout -b $branchName $baseTag');
        print("✓ Created new branch $branchName from $baseTag");
      }
    } else {
      // Check if branch exists on remote
      var remoteBranches = 'git branch -r --list origin/$branchName'.toList();
      if (remoteBranches.isNotEmpty) {
        print("Branch $branchName exists on remote.");
        String checkoutRemote = ask(
          'Checkout remote branch? [Y/n]:',
          required: false,
          defaultValue: 'Y',
        );
        if (checkoutRemote.toUpperCase() == 'Y') {
          run('git checkout -b $branchName origin/$branchName');
          print("✓ Checked out remote branch $branchName");
        } else {
          run('git checkout -b $branchName $baseTag');
          print("✓ Created new branch $branchName from $baseTag");
        }
      } else {
        run('git checkout -b $branchName $baseTag');
        print("✓ Created new branch $branchName from $baseTag");
      }
    }

    // Step 2: Apply the selected commits (oldest to newest for proper chronology)
    print("\n=== Step 2: Applying ${commitHashes.length} commit(s) ===");

    // Reverse the order to apply oldest commits first (chronological order)
    var commitHashesInOrder = commitHashes.reversed.toList();

    print("Applying commits in chronological order (oldest to newest):");
    for (var hash in commitHashesInOrder) {
      var commitInfo = commits.firstWhere(
        (c) => c.startsWith(hash),
        orElse: () => hash,
      );
      print("  - $commitInfo");
    }

    for (int i = 0; i < commitHashesInOrder.length; i++) {
      var commitHash = commitHashesInOrder[i];
      var commitInfo = commits.firstWhere(
        (c) => c.startsWith(commitHash),
        orElse: () => commitHash,
      );
      print(
        "\nApplying commit ${i + 1}/${commitHashesInOrder.length}: $commitInfo",
      );

      try {
        run('git cherry-pick $commitHash');
        print("✓ Commit $commitHash applied successfully");
      } catch (e) {
        print("❌ Failed to cherry-pick commit $commitHash");
        print("This might be due to conflicts. Please resolve manually:");
        print("  1. Fix conflicts in the listed files");
        print("  2. Run: git add <resolved-files>");
        print("  3. Run: git cherry-pick --continue");
        print("  4. Continue with remaining commits manually or re-run script");

        // Ask user how to handle the conflict
        String continueChoice = ask(
          '\nHow do you want to proceed?\n'
          '  a) Abort cherry-pick and exit\n'
          '  b) Skip this commit and continue with next\n'
          '  c) Assume conflicts will be resolved manually and continue\n'
          '  [a/b/c]:',
          required: false,
          defaultValue: 'a',
        );

        switch (continueChoice.toLowerCase()) {
          case 'a':
            run('git cherry-pick --abort');
            print("Cherry-pick aborted. Exiting...");
            rethrow;
          case 'b':
            run('git cherry-pick --skip');
            print("Skipped commit $commitHash, continuing with next...");
            continue;
          case 'c':
            print(
              "Continuing with assumption that conflicts will be resolved...",
            );
            print(
              "Make sure to run 'git cherry-pick --continue' after resolving conflicts",
            );
            break;
          default:
            run('git cherry-pick --abort');
            print("Invalid choice. Cherry-pick aborted. Exiting...");
            rethrow;
        }
      }
    }

    print("✓ All selected commits processed successfully");

    // Step 3: Create Docker images
    print("\n=== Step 3: Creating Docker images ===");
    for (var app in selectedApps.keys) {
      print("Building Docker image for $app...");
      String dockerImage = 'growerp/$app';
      String dockerTag = newTag;

      try {
        if (app == 'growerp-moqui') {
          // Build from moqui directory
          print("Building Moqui backend image...");
          run(
            'docker build --progress=plain -t $dockerImage:$dockerTag '
            '--label version=$dockerTag ../moqui --no-cache',
            workingDirectory: currentDir,
          );
        } else {
          // Build Flutter app from flutter directory
          print("Building Flutter app image for $app...");

          // Ensure the Dockerfile exists
          var dockerFile = File('$currentDir/packages/$app/Dockerfile');
          if (!dockerFile.existsSync()) {
            print("❌ Dockerfile not found: ${dockerFile.path}");
            continue;
          }

          run(
            'docker build --file packages/$app/Dockerfile '
            '--progress=plain -t $dockerImage:$dockerTag '
            '--label version=$dockerTag . --no-cache',
            workingDirectory: currentDir,
          );
        }

        selectedApps[app] =
            'docker images -q $dockerImage:$dockerTag'.firstLine ?? '?';
        print("✓ Created Docker image $dockerImage:$dockerTag");

        // Push to Docker Hub (if requested)
        if (pushToDockerHub.toUpperCase() == 'Y') {
          print("Pushing $dockerImage:$dockerTag to Docker Hub...");
          try {
            run('docker push $dockerImage:$dockerTag');
            print("✓ Pushed $dockerImage:$dockerTag");
          } catch (e) {
            print("❌ Failed to push $dockerImage:$dockerTag");
            print("Make sure you're logged in to Docker Hub: docker login");
            rethrow;
          }
        }
      } catch (e) {
        print("❌ Failed to build Docker image for $app: $e");
        rethrow;
      }
    }

    // Step 4: Create Git tag and push to GitHub
    print("\n=== Step 4: Creating Git tag and pushing to GitHub ===");
    run('git tag $newTag');
    print("✓ Created Git tag $newTag");

    run('git push origin $branchName');
    print("✓ Pushed branch $branchName to GitHub");

    run('git push origin $newTag');
    print("✓ Pushed tag $newTag to GitHub");

    print("\n🎉 === Hot Fix Release Complete! === 🎉");
    print("✓ Branch: $branchName");
    print("✓ Tag: $newTag");
    print(
      "✓ Docker images built and ${pushToDockerHub.toUpperCase() == 'Y' ? 'pushed' : 'ready'}",
    );
    print("✓ Changes pushed to GitHub");

    // Show built apps summary
    print("\nBuilt applications:");
    selectedApps.forEach((app, imageId) {
      var shortId = imageId.length > 12 ? imageId.substring(0, 12) : imageId;
      print("  - growerp/$app:$newTag (Image ID: $shortId)");
    });

    if (pushToDockerHub.toUpperCase() == 'Y') {
      print("\n📦 Docker images are available at:");
      selectedApps.forEach((app, _) {
        print("  - https://hub.docker.com/r/growerp/$app/tags");
      });
    }

    print("\n🔧 Next steps:");
    print("  1. Verify the hot fix in your staging environment");
    print("  2. Deploy to production using tag: $newTag");
    print("  3. Monitor the deployment");
    print("\n💡 To return to master branch:");
    print("  git checkout master");
  } catch (e) {
    print("\n❌ Error during hot fix process: $e");
    print("\n🧹 Cleaning up...");

    try {
      // Check current branch before cleanup
      var currentBranch = 'git branch --show-current'.firstLine ?? '';

      if (currentBranch == branchName) {
        print("Switching back to master...");
        run('git checkout master');
      }

      // Check if branch exists before trying to delete
      var branches = 'git branch --list $branchName'.toList();
      if (branches.isNotEmpty) {
        print("Deleting branch $branchName...");
        run('git branch -D $branchName');
      }

      // Check if tag exists locally before trying to delete
      var localTags = 'git tag --list $newTag'.toList();
      if (localTags.isNotEmpty) {
        print("Deleting local tag $newTag...");
        run('git tag -d $newTag');
      }

      print("✓ Local cleanup completed");

      // Note about remote cleanup
      print(
        "\n⚠️  If any remote resources were created, you may need to clean them up manually:",
      );
      print("  git push origin --delete $branchName  # if branch was pushed");
      print("  git push origin --delete $newTag      # if tag was pushed");
    } catch (cleanupError) {
      print("⚠️  Automatic cleanup failed: $cleanupError");
      print("\n🔧 Manual cleanup steps:");
      print("  git checkout master");
      print("  git branch -D $branchName");
      print("  git tag -d $newTag");
      print("  git push origin --delete $branchName");
      print("  git push origin --delete $newTag");
    }

    exit(1);
  }
}
