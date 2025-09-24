# GrowERP Hot Fix Release Tool

This directory contains all the tools and utilities for creating hot fix releases in the GrowERP project.

## Files

- **`hotfix_release.dart`** - Main hot fix script (Dart)
- **`hotfix_release.sh`** - Bash wrapper script with environment validation
- **`README.md`** - Comprehensive documentation
- **`hotfix_config.json`** - Configuration file for customizing defaults
- **`test_hotfix.dart`** - Validation script to test dependencies

## Quick Start

### From flutter directory:
```bash
./hotfix.sh
```

### From hotfix directory:
```bash
./hotfix_release.sh
# or
dart hotfix_release.dart
```

## Directory Structure

```
flutter/
├── hotfix.sh                 # Launcher script
└── hotfix/
    ├── hotfix_release.dart   # Main script
    ├── hotfix_release.sh     # Wrapper script
    ├── README.md             # Full documentation
    ├── hotfix_config.json    # Configuration
    └── test_hotfix.dart      # Validation tests
```

## Process Overview

The hot fix tool automates the following workflow:
1. Creates or reuses a branch named `hotfix-{base-version}` (e.g., `hotfix-1.10.0`)
2. Applies selected commit(s) from master to the branch (supports multiple commits)
3. Builds Docker images with the new version tag (e.g., `1.10.1`)
4. Pushes images to Docker Hub (optional)
5. Pushes the branch and tag to GitHub

### Branch Reuse Benefits
- Multiple hot fixes can be applied to the same base version
- Maintains clean commit history on the hotfix branch
- Reduces branch proliferation in the repository

## Support

- See `README.md` for detailed documentation
- Run `dart test_hotfix.dart` to validate your environment
- All scripts include comprehensive error handling and cleanup