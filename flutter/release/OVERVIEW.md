# GrowERP Release Tool Overview

This directory contains the enhanced production release tooling for GrowERP applications. The tools have been reorganized and improved from the original `createPushDockerImages.dart` to provide better reliability, usability, and maintainability.

## 📁 Directory Structure

```
release/
├── README.md                           # Comprehensive documentation
├── release.sh                          # Main launcher script (recommended)
├── release_tool.dart                   # Core release automation tool
├── release_config.json                 # Configuration file
├── test_release.dart                   # Dependency and functionality tests
├── createPushDockerImages_original.dart # Original script (backup)
└── OVERVIEW.md                         # This file
```

## 🚀 Quick Start

```bash
# From flutter/ directory (recommended)
./release.sh

# Or from flutter/release/ directory
dart release_tool.dart
```

## 🔧 Tools Comparison

| Feature | Original Script | New Release Tool |
|---------|----------------|------------------|
| **User Interface** | Command-line prompts | Interactive selection menus |
| **Error Handling** | Basic | Comprehensive with recovery |
| **Configuration** | Hardcoded | JSON-based configuration |
| **Validation** | Minimal | Full environment validation |
| **Documentation** | Inline comments | Comprehensive README |
| **Testing** | None | Automated test script |
| **Workspace Modes** | Repository only | Local + Repository modes |
| **Application Selection** | All or manual list | Interactive selection |
| **Version Management** | All apps together | Flexible per-app versioning |
| **Progress Tracking** | Basic print statements | Detailed status updates |

## 📊 Workflow Improvements

### Before (Original Script)
```
Ask questions → Build all → Push → Commit → Tag
```

### After (Enhanced Tool)
```
Load Config → Validate Environment → Interactive Selection → 
Calculate Versions → Show Summary → Confirm → Execute → 
Report Results
```

## 🎯 Key Benefits

1. **Reliability**: Comprehensive validation and error handling
2. **Usability**: Clear prompts, status updates, and summaries
3. **Flexibility**: Local vs repository modes, selective builds
4. **Maintainability**: Configuration-driven, well-documented
5. **Testability**: Automated testing of dependencies
6. **Safety**: Confirmation steps and detailed summaries

## 🔄 Migration Guide

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

## 🧪 Testing

Always test before using in production:
```bash
dart test_release.dart
```

## 📚 Documentation

- **Complete Guide**: [README.md](README.md)
- **Process Documentation**: [../../docs/GrowERP_Version_Management_and_Release_Process.md](../../docs/GrowERP_Version_Management_and_Release_Process.md)
- **Hotfix Tools**: [../hotfix/README.md](../hotfix/README.md)

## 🤝 Contributing

When modifying the release tools:
1. Update configuration schema if needed
2. Add tests for new functionality
3. Update documentation
4. Test thoroughly before committing

---

*This enhanced tooling is part of GrowERP's commitment to reliable, automated releases while maintaining developer productivity.*