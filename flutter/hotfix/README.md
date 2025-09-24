# GrowERP Hot Fix Release Tool

This tool automates the process of creating hot fix releases for GrowERP production deployments.

## Overview

The hot fix tool performs the following steps:

1. **Branch Creation**: Creates a new branch from a selected production tag (default: latest tag)
2. **Commit Application**: Applies a selected commit from master branch (default: latest commit)
3. **Version Update**: Updates version numbers in relevant package files and commits changes
4. **Docker Build**: Creates Docker images for selected applications with the new tag (without `latest` tag)
5. **Docker Push**: Optionally pushes images to hub.docker.com (default: yes)
6. **Git Push**: Pushes the new branch and tag to GitHub

## Prerequisites

- Dart SDK installed
- Docker installed and running
- Git repository with proper remote access
- `dcli` package (will be installed automatically if missing)

## Usage

### Quick Start

From the `flutter` directory:

```bash
# Using the launcher script (recommended)
./hotfix.sh

# Or from the hotfix directory
cd hotfix
./hotfix_release.sh

# Or run the Dart script directly
cd hotfix  
dart hotfix_release.dart
```

### Interactive Process

The script will guide you through the following steps:

1. **Select Base Tag**: Choose the production tag to base the hot fix on
   - Shows the 10 most recent tags
   - Default: latest tag

2. **Select Commit(s)**: Choose which commit(s) from master to apply
   - Shows the 15 most recent commits since the base tag
   - **Single commit**: Enter commit hash or number (e.g., `a1b2c3d` or `1`)
   - **Multiple commits**: Comma-separated (e.g., `1,3,5` or `a1b2c3d,e4f5g6h`)
   - **Range**: Dash-separated numbers (e.g., `1-3` for commits 1,2,3)
   - Default: latest commit

3. **New Tag Name**: Specify the new tag name
   - Default: automatically increments patch version (e.g., 1.3.42 → 1.3.43)
   - Must follow format: `1.2.3`

4. **Select Applications**: Choose which applications to build
   - Available: `admin`, `freelance`, `health`, `hotel`, `support`, `growerp-moqui`
   - Default: all applications
   - Enter comma-separated list for specific apps

5. **Docker Hub Push**: Confirm whether to push to Docker Hub
   - Default: Yes

6. **Final Confirmation**: Review summary and confirm execution

### Example Session

```
=== GrowERP Hot Fix Release Tool ===

Fetching available production tags...

Available production tags (latest 10):
  1. 1.3.42
  2. 1.3.41
  3. 1.3.40
  ...

Select base production tag [default: 1.3.42]: 

Fetching commits since 1.3.42...

Recent commits on master since 1.3.42:
  1. a1b2c3d Fix critical security vulnerability
  2. e4f5g6h Update user authentication logic
  3. i7j8k9l Performance improvement
  4. m1n2o3p UI bug fix
  ...

Select commit(s) to apply:
  - Single commit: commit-hash or number (e.g., "a1b2c3d" or "1")
  - Multiple commits: comma-separated (e.g., "1,3,5" or "a1b2c3d,e4f5g6h")
  - Range: dash-separated numbers (e.g., "1-3" for commits 1,2,3)
  [default: latest (a1b2c3d)]: 1,3,4 

Enter new tag name [default: 1.3.43]: 

App image name list (comma separated) [default: all apps]: admin,hotel

Push to hub.docker.com? [Y/n]: 

=== Hot Fix Summary ===
Base tag: 1.3.42
Commits to apply: a1b2c3d, i7j8k9l, m1n2o3p
New tag: 1.3.43
Apps to build: admin, hotel
Push to Docker Hub: Y
Branch name: hotfix-1.3.42

Proceed with hot fix? [Y/n]: Y
```

## Generated Artifacts

### Git Artifacts
- **Branch**: `hotfix-1.3.42` (reusable branch based on base tag)
- **Tag**: `1.3.43` (incremented version tag)
- **Commits**: Version updates and cherry-picked changes

### Docker Artifacts
- **Images**: `growerp/admin:1.3.43`, `growerp/hotel:1.3.43` (example)
- **Registry**: Pushed to hub.docker.com (if confirmed)

### File Changes
- **Git Branch**: New hotfix branch with cherry-picked commits
- **Docker Images**: Built with specified tag version
- **Version Control**: Manual control over version numbers

## Error Handling

The script includes comprehensive error handling:

- **Validation**: Checks for valid tags, commits, and app names
- **Git State**: Warns about uncommitted changes
- **Docker**: Verifies Docker is running
- **Cleanup**: Automatically cleans up on failure
- **Rollback**: Provides instructions for manual cleanup if needed

## Manual Cleanup

If the script fails and automatic cleanup doesn't work:

```bash
# Switch back to master
git checkout master

# Delete the hot fix branch (if created)
git branch -D hotfix-1.3.42

# Delete the tag (if created)
git tag -d 1.3.43

# Remove from remote (if pushed)
git push origin --delete hotfix-1.3.42
git push origin --delete 1.3.43
```

## Configuration

The script can be customized using `hotfix_config.json`:

```json
{
  "defaultApps": ["admin", "freelance", "health", "hotel", "support", "growerp-moqui"],
  "dockerRegistry": "growerp",
  "defaultPushToDockerHub": true,
  "branchPrefix": "hotfix-",
  "versionTagPrefix": "v",
  "maxDisplayTags": 10,
  "maxDisplayCommits": 15
}
```

## Branch Reuse Strategy

The tool uses a smart branch naming strategy for efficient hot fix management:

- **Branch naming**: `hotfix-{base-version}` (e.g., `hotfix-1.3.42`)
- **Reusable branches**: Multiple hot fixes can be applied to the same base version
- **Automatic detection**: Checks for existing local and remote branches
- **User choice**: Option to reuse existing branch or create fresh one

### Multiple Hot Fixes Example

**Scenario**: Multiple critical fixes needed for production version `1.3.42`

```bash
# First hot fix: Security patch
Base tag: 1.3.42 → New tag: 1.3.43
Branch: hotfix-1.3.42 (created)
Applied commit: a1b2c3d (security fix)

# Second hot fix: Bug fix (reuses branch)
Base tag: 1.3.42 → New tag: 1.3.44
Branch: hotfix-1.3.42 (reused)
Applied commit: e4f5g6h (bug fix)

# Third hot fix: Performance improvement (reuses branch)
Base tag: 1.3.42 → New tag: 1.3.45
Branch: hotfix-1.3.42 (reused)
Applied commit: i7j8k9l (performance fix)
```

**Result**: One clean hotfix branch with multiple production releases.

## Multiple Commit Selection

The tool supports applying multiple commits in a single hotfix operation:

### Selection Methods

1. **Single Commit**
   ```
   Select commit(s): 1
   Select commit(s): a1b2c3d
   ```

2. **Multiple Commits**
   ```
   Select commit(s): 1,3,5
   Select commit(s): a1b2c3d,i7j8k9l,m1n2o3p
   ```

3. **Range Selection**
   ```
   Select commit(s): 1-3    # Applies commits 1, 2, and 3
   Select commit(s): 2-5    # Applies commits 2, 3, 4, and 5
   ```

### Conflict Handling

When applying multiple commits, if a conflict occurs:
- **Abort**: Stop the process and exit
- **Skip**: Skip the problematic commit and continue
- **Continue**: Assume manual resolution and proceed

### Commit Application Order

**Important**: Commits are always applied in chronological order (oldest to newest), regardless of your selection order. This reduces conflicts and maintains proper commit dependencies.

```bash
# Display order (newest first):
  1. c3d4e5f Latest fix
  2. b2c3d4e Middle fix  
  3. a1b2c3d Oldest fix

# Selection: 1,3 
# Application order: a1b2c3d → c3d4e5f (oldest to newest)
```

### Use Cases

- **Related Fixes**: Apply multiple related bug fixes together
- **Feature Patches**: Include dependent commits in correct order  
- **Comprehensive Updates**: Bundle security, performance, and bug fixes

## Notes

- Branch reuse allows multiple hot fixes on the same base version
- Docker images are built without the `latest` tag to avoid affecting current deployments
- The process preserves the original commit history through cherry-picking
- Version numbers are NOT automatically updated - you control versioning manually
- Configuration can be customized via `hotfix_config.json`

## Troubleshooting

### Common Issues

1. **"No tags found"**: Ensure you're in the correct repository with existing tags
2. **"Docker not running"**: Start Docker Desktop or Docker daemon
3. **"Invalid commit hash"**: Use `git log --oneline` to find valid commit hashes
4. **"Permission denied"**: Ensure scripts are executable (`chmod +x`)

### Debug Mode

For debugging, you can modify the script to add more verbose output or dry-run capabilities by editing the Dart script directly.