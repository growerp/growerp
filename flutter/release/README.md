# GrowERP Production Release Tool

A comprehensive, automated tool for creating production releases of GrowERP applications. This tool manages version increments, Docker image creation, and deployment coordination with proper Git tagging and Docker Hub integration.

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
  "tempWorkspaceDir": "/tmp/growerp",
  "defaultPushToDockerHub": true,
  "defaultPushToTestServer": false,
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
| `tempWorkspaceDir` | Temporary directory for repository mode | `/tmp/growerp` |
| `defaultPushToDockerHub` | Push images to Docker Hub by default | `true` |
| `defaultPushToTestServer` | Use repository mode by default | `false` |
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
   - Configure push options
   - Determine workspace mode

3. **Version Calculation**
   - Scan current versions across all apps
   - Calculate next version numbers
   - Display summary for confirmation

4. **Release Execution**
   - Update version files (if configured)
   - Build Docker images
   - Push to Docker Hub (if configured)
   - Create Git tags and commit
   - Display final summary

### Version Management
The tool uses a **unified versioning approach**:
- All applications share the same major.minor.patch version
- Build numbers remain application-specific
- Version increments affect all selected applications

### Workspace Modes

#### Local Mode (Default)
- Uses current working directory
- Faster for development builds
- Preserves local changes and branches

#### Repository Mode
- Clones/updates from Git repository
- Ensures clean build environment
- Required for production releases to test server

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
   Push to test server: No

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

## 🔍 Troubleshooting

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

- [GrowERP Version Management and Release Process](../../docs/GrowERP_Version_Management_and_Release_Process.md)
- [Hotfix Documentation](../hotfix/README.md)
- [GrowERP Extensibility Guide](../../docs/GrowERP_Extensibility_Guide.md)

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

This tool is part of the GrowERP project and follows the same CC0 1.0 Universal license.

---

*For more information about GrowERP, visit [https://www.growerp.com](https://www.growerp.com)*