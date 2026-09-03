# GrowERP Production Release Tool

A comprehensive, automated tool for creating production releases of GrowERP applications. This tool manages version increments, Docker image creation, and deployment coordination with proper Git tagging and Docker Hub integration.

## � Directory Structure

```
release/
├── README.md              # This file — comprehensive documentation
├── release_tool.dart      # Core release automation tool
├── release_config.json    # Configuration file
├── test_release.dart      # Dependency and functionality tests
└── gce-setup.sh           # GCE setup script
```

## 🔄 Release Philosophy

The release process follows a **repository-first** approach to ensure consistency and reproducibility:

1. **Clone** current repository to temp directory (`/tmp/growerpRelease`)
2. **Overlay** local Dockerfiles over the cloned workspace (so uncommitted changes are always used)
3. **Update** versions in the temp workspace
4. **Commit & Tag** changes, push to GitHub
5. **Build** Docker images from the temp workspace
6. **Push** Docker images to Docker Hub

### Why This Approach?

- **Consistency** — Docker images are always built from a clean, known state
- **Traceability** — Git tags match Docker image versions exactly
- **Reproducibility** — Anyone can rebuild the exact same image from the tagged commit
- **Clean State** — Fresh clone ensures no local artifacts
- **Local Changes** — Uncommitted Dockerfile changes (e.g. base image updates) are automatically applied before building

## 🚀 Quick Start

### Prerequisites
- Dart SDK (3.0+)
- Docker
- Git
- Access to GrowERP repository

### Installation
```bash
# Install dcli (if not already installed)
dart pub global activate dcli

# Make the script executable
chmod +x release.sh
```

### Basic Usage
```bash
# Run from flutter directory (recommended)
./release.sh

# Or run from flutter/release directory
cd release && dart release_tool.dart
```

## 📋 Features

### ✨ Core Functionality
- **Interactive Application Selection**: Choose which applications to build
- **Version Management**: Automated patch, minor, or major version increments
- **Docker Integration**: Automated image building with proper tagging
- **Git Integration**: Automatic tagging and repository management
- **Workspace Modes**: Support for local development and repository-based releases

### 🔧 Advanced Features
- **Configuration Management**: JSON-based configuration with sensible defaults
- **Environment Validation**: Comprehensive pre-flight checks
- **Error Handling**: Robust error detection and recovery
- **Progress Tracking**: Clear status updates throughout the process
- **Cleanup**: Automatic cleanup of temporary resources

### 🎯 Key Benefits
1. **Reliability**: Comprehensive validation and error handling
2. **Usability**: Clear prompts, status updates, and summaries
3. **Flexibility**: Local vs repository modes, selective builds
4. **Maintainability**: Configuration-driven, well-documented
5. **Testability**: Automated testing of dependencies
6. **Safety**: Confirmation steps and detailed summaries

### 📦 Supported Applications
- `admin` - Full-featured ERP application
- `freelance` - Freelance project management
- `health` - Healthcare management
- `hotel` - Hotel management system
- `support` - Customer support system
- `growerp-moqui` - Backend component

## 🛠️ Configuration

### Configuration File: `release_config.json`
```json
{
  "defaultApps": [
    "admin", "freelance", "health", "hotel", "support", "growerp-moqui"
  ],
  "dockerRegistry": "growerp",
  "repositoryUrl": "git@github.com:growerp/growerp.git",
  "tempWorkspaceDir": "/tmp/growerpRelease",
  "defaultPushToDockerHub": true,
  "defaultPushToGitHub": false,
  "versionTagPrefix": "",
  "dockerBuildArgs": {
    "progress": "plain",
    "no-cache": true
  },
  "gitSettings": {
    "autoStash": true,
    "autoPull": true,
    "autoCleanup": true
  },
  "versionUpgrade": {
    "defaultPatch": true,
    "defaultMinor": false,
    "defaultMajor": false
  }
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `defaultApps` | List of applications to build | All available apps |
| `dockerRegistry` | Docker registry/organization name | `growerp` |
| `repositoryUrl` | Git repository URL | GrowERP GitHub repo |
| `tempWorkspaceDir` | Temporary directory for repository mode | `/tmp/growerpRelease` |
| `defaultPushToDockerHub` | Push images to Docker Hub by default | `true` |
| `defaultPushToGitHub` | Use repository mode by default | `false` |
| `versionTagPrefix` | Prefix for version tags | `` (none) |

## 🎯 Usage Scenarios

### 1. Standard Production Release
```bash
./release.sh
# Select: All applications
# Version: Patch increment
# Push: Yes to Docker Hub
# Workspace: Local
```

### 2. Feature Release
```bash
./release.sh
# Select: Specific applications
# Version: Minor increment
# Push: Yes to Docker Hub and test server
# Workspace: Repository (for clean build)
```

### 3. Major Version Release
```bash
./release.sh
# Select: All applications
# Version: Major increment
# Push: Yes to Docker Hub and test server
# Workspace: Repository
```

### 4. Development Build
```bash
./release.sh
# Select: Single application
# Version: No increment
# Push: No
# Workspace: Local
```

## 🔄 Release Process

### Standard Workflow
1. **Environment Validation**
   - Check directory structure
   - Validate Git repository
   - Verify Docker availability
   - Load configuration

2. **User Input Collection**
   - Select applications to build
   - Choose version increment type
   - Configure push options (Docker Hub / GitHub)

3. **Workspace Setup**
   - Clone the repository to `/tmp/growerpRelease`
   - Overlay all local `Dockerfile`s over the clone so uncommitted changes are used
   - This applies to both `flutter/packages/*/Dockerfile` and `moqui/Dockerfile`

4. **Version Calculation**
   - Scan current versions across all packages
   - Calculate next version number
   - Display summary for confirmation

5. **Release Execution**
   - Update `pubspec.yaml` / `component.xml` version files
   - Commit version changes and create a Git tag
   - Push commit and tag to GitHub
   - Build Docker images from the temp workspace
   - Push to Docker Hub (if configured)
   - Display final summary

### Version Management
The tool uses a **unified versioning approach**:
- All applications share the same major.minor.patch version
- Build numbers remain application-specific
- Version increments affect all selected applications

### Resume Support
If the release process is interrupted, a `release_state.json` file preserves progress. On the next run you will be prompted to resume.
- If `/tmp/growerpRelease` no longer exists (e.g. after a reboot), it is automatically re-cloned
- Dockerfiles are overlaid again after re-cloning

## 🐳 Docker Build Details

### Base Image
All Flutter build stages use `ghcr.io/cirruslabs/flutter:stable` and run as `root`.

### Flutter App Dockerfiles (`packages/*/Dockerfile`)
- **Stage 1** — installs dependencies, activates melos, builds Flutter web app
- **Stage 2** — copies build output into `nginx`

### growerp-moqui Dockerfile (`moqui/Dockerfile`)
- **Stage 1 (`build-flutter`)** — clones the GrowERP repo, builds Flutter web apps with `--wasm`
- **Stage 2 (`build-env`)** — copies from stage 1, builds the Moqui WAR with Gradle
- **Stage 3 (final)** — `eclipse-temurin:11-jdk` runtime image

### Important: Local Dockerfile Overlay
Because the release tool clones from GitHub, uncommitted Dockerfile changes would normally be lost. The tool automatically copies all local `Dockerfile`s into the cloned workspace before building, ensuring your local versions are always used.

## 🧪 Testing

### Run Tests
```bash
# From flutter directory
cd release && dart test_release.dart

# Or from flutter/release directory
dart test_release.dart
```

### Test Coverage
- Directory structure validation
- Git repository detection
- Configuration loading
- Docker availability
- Version parsing logic
- File operations
- Application detection

## 📊 Output Examples

### Successful Release
```
=== GrowERP Production Release Tool ===

✓ Configuration loaded from release_config.json
✓ Environment validation completed

📦 Available applications:
   1. admin
   2. freelance
   3. hotel

Selected: admin, hotel

📊 Calculating version information...
   admin: 1.9.0+1
   hotel: 1.9.0+2
   Next version: 1.9.1

📋 Release Summary:
   Applications: admin, hotel
   New version: 1.9.1
   Workspace: Local
   Push to Docker Hub: Yes
   Push to GitHub: No

🚀 Starting release process...

📦 Processing admin...
   Building Docker image: growerp/admin:latest
   ✓ Image built successfully: abc123def456
   Pushing to Docker Hub: growerp/admin:latest
   ✓ Latest image pushed successfully
   Tagging and pushing version: growerp/admin:1.9.1
   ✓ Version image pushed successfully
✓ admin completed

🎯 Release Summary:
   Version: 1.9.1
   Applications:
     • admin (abc123def456)
     • hotel (def456abc789)

💡 Next steps:
   • Update production docker-compose.yaml with version 1.9.1
   • Deploy to production: docker-compose up -d
   • Monitor application startup and logs

🎉 Release process completed successfully!
```

## � Migration Guide

### For Existing Users
- The original script location (`flutter/createPushDockerImages.dart`) now shows a migration notice
- All original functionality is preserved and enhanced
- The original script is backed up as `createPushDockerImages_original.dart`

### CI/CD Integration
Update your automation scripts to use:
```bash
# Old
dart createPushDockerImages.dart

# New (from flutter directory)
./release.sh
```

## �🔍 Troubleshooting

### Common Issues

#### "Please run this script from the flutter directory"
- **Cause**: Script executed from wrong location
- **Solution**: Navigate to `flutter/` or `flutter/release/` directory

#### "Docker is not available"
- **Cause**: Docker not installed or not running
- **Solution**: Install Docker and ensure it's running

#### "Git repository not found"
- **Cause**: Not in a Git repository or Git not installed
- **Solution**: Ensure you're in the GrowERP repository with Git available

#### "Configuration loading failed"
- **Cause**: Malformed JSON in config file
- **Solution**: Validate JSON syntax in `release_config.json`

#### "Version parsing failed"
- **Cause**: Unexpected version format in pubspec.yaml files
- **Solution**: Ensure versions follow semantic versioning (major.minor.patch+build)

#### Docker build uses wrong base image
- **Cause**: Committed Dockerfiles on GitHub differ from local
- **Solution**: The tool automatically overlays local Dockerfiles; ensure you run from the `flutter/` directory so paths resolve correctly

#### Resume re-clones but still fails
- **Cause**: `/tmp/growerpRelease` was cleaned but state file references old step
- **Solution**: The tool re-clones and re-overlays Dockerfiles automatically; if it still fails, delete `release/release_state.json` and start fresh

#### Docker image has old code
- **Cause**: Git push did not succeed before Docker build
- **Solution**: Verify git push succeeded before Docker build (check GitHub)

#### Build fails with "branch not found"
- **Cause**: Changes not pushed or tag doesn't exist on GitHub
- **Solution**: Ensure changes are pushed and tag exists on GitHub

#### Version mismatch between tag and image
- **Cause**: Versions were not committed before building
- **Solution**: Release workflow now enforces matching — versions are committed before building

### Debug Mode
For detailed debugging, modify the script to enable verbose output:
```dart
// Add to main() function
var debug = true; // Enable debug mode
```

### Log Files
The tool doesn't create log files by default, but you can redirect output:
```bash
./release.sh 2>&1 | tee release.log
```

## 🔧 Customization

### Adding New Applications
1. Add the application name to `defaultApps` in config
2. Ensure the application has:
   - `pubspec.yaml` in `packages/[app]/`
   - `Dockerfile` in `packages/[app]/`
   - Proper version format

### Custom Docker Registry
```json
{
  "dockerRegistry": "your-registry.com/your-org"
}
```

### Custom Version Prefix
```json
{
  "versionTagPrefix": "v"
}
```
This creates tags like `v1.9.1` instead of `1.9.1`.

## 🚦 Integration with CI/CD

### GitHub Actions Example
```yaml
name: Production Release
on:
  workflow_dispatch:
    inputs:
      version_type:
        description: 'Version increment type'
        required: true
        default: 'patch'
        type: choice
        options:
        - patch
        - minor
        - major

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: dart-lang/setup-dart@v1
    - name: Run release tool
      run: |
        cd flutter/release
        dart pub global activate dcli
        # Configure non-interactive mode here
        dart release_tool.dart
```

## 📚 Related Documentation

- [GrowERP CI Store Maintenance Guide](../../docs/GrowERP_CI_Store_Maintenance_Guide.md)
- [Hotfix Documentation](../hotfix/README.md)
- [GrowERP Extensibility Guide](../../docs/GrowERP_Extensibility_Guide.md)

## 📁 Key Files

| File | Purpose |
|------|---------|
| `release.sh` | Entry point — validates environment and launches the tool |
| `release/release_tool.dart` | Full release automation logic |
| `release/release_config.json` | Configuration (registry, apps, temp dir, etc.) |
| `release/release_state.json` | Auto-generated resume state (deleted on success) |
| `release/test_release.dart` | Unit tests |
| `release/gce-setup.sh` | GCE setup script |
| `../packages/*/Dockerfile` | Flutter web app Docker build definitions |
| `../../moqui/Dockerfile` | Backend (Moqui + Flutter web) Docker build definition |

## 🤝 Contributing

### Adding Features
1. Modify `release_tool.dart` for core functionality
2. Update `release_config.json` for new configuration options
3. Add tests to `test_release.dart`
4. Update this README

### Code Style
- Follow Dart conventions
- Use descriptive variable names
- Add comments for complex logic
- Maintain error handling patterns

## 📄 License

This tool is part of the GrowERP project and follows the same Apache License 2.0.

---

*For more information about GrowERP, visit [https://www.growerp.com](https://www.growerp.com)*