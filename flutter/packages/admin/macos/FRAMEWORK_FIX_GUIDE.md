# Fixing "Malformed Framework" Error for macOS App Store Upload

## 🐛 The Problem

When uploading to App Store Connect, you received:

```
90291: Malformed Framework. The framework bundle objective_c 
(admin.app/Contents/Frameworks/objective_c.framework) must contain 
a symbolic link 'Resources' -> 'Versions/Current/Resources'.
```

## 🔍 Root Cause

Some Flutter plugin frameworks (like `objective_c.framework`) don't follow Apple's required bundle structure for App Store distribution. They need:

```
SomeFramework.framework/
  ├── Versions/
  │   ├── A/
  │   │   ├── SomeFramework (binary)
  │   │   └── Resources/
  │   └── Current -> A (symlink)
  ├── SomeFramework -> Versions/Current/SomeFramework (symlink)
  └── Resources -> Versions/Current/Resources (symlink)
```

But Flutter sometimes builds them as:

```
SomeFramework.framework/
  ├── SomeFramework (binary)
  └── Resources/ (directory, not symlink) ❌
```

## ✅ The Solution

I've created automated scripts that fix the framework structures before upload.

### Quick Fix - Use the Automated Script

```bash
cd /Users/hans/growerp/flutter/packages/admin
./macos/archive-with-fixes.sh
```

This script:
1. Builds the Flutter app
2. Fixes all framework structures
3. Creates an Xcode archive
4. Fixes frameworks in the archive again
5. Validates the structure

Then upload via Xcode Organizer or Transporter.

### Manual Fix (if needed)

If you already have an archive:

```bash
cd /Users/hans/growerp/flutter/packages/admin
./macos/fix-frameworks.sh
```

## 📝 Scripts Created

| Script | Purpose |
|--------|---------|
| `archive-with-fixes.sh` | **Complete solution** - builds, fixes, and archives |
| `export-archive.sh` | Export archive for App Store |
| `fix-frameworks.sh` | Fix frameworks in existing build |
| `build-with-fixes.sh` | Build with framework fixes |

## 🎯 Recommended Workflow

**For App Store Upload:**

```bash
# 1. Build and archive with fixes
./macos/archive-with-fixes.sh

# 2. The script will ask if you want to export
# Or manually export:
./macos/export-archive.sh

# 3. Upload via Transporter or Xcode Organizer
```

**Alternative - Xcode GUI:**

After running `archive-with-fixes.sh`:
1. Open Xcode → Window → Organizer
2. Select the latest archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Upload

## 🔍 Verify the Fix

To check if a framework is properly structured:

```bash
FRAMEWORK="path/to/SomeFramework.framework"

# Check if Resources is a symlink (good)
ls -la "$FRAMEWORK/Resources"

# Should show: Resources -> Versions/Current/Resources
```

## ⚠️ Common Issues

### "xcrun: error: unable to find utility "altool""

Use Transporter app instead, or update Xcode Command Line Tools.

### "No signing identity found"

Make sure you have a valid "Apple Distribution" certificate:

```bash
security find-identity -v -p codesigning
```

### Framework still shows as malformed

1. Clean everything: `flutter clean`
2. Delete build folder: `rm -rf build`
3. Run the archive script again

## 📱 After Upload

1. Wait 15-30 minutes for App Store Connect processing
2. Check for any new validation errors
3. Test in TestFlight
4. Submit for review

## 🆘 If Problems Persist

If the automated fix doesn't work:

1. **Check which framework is failing:**
   - Look at the App Store Connect error message
   - Note the exact framework name

2. **Manually inspect:**
   ```bash
   cd build/macos/Build/Products/Release/admin.app/Contents/Frameworks
   ls -la *.framework/
   ```

3. **Report to Flutter:**
   - This is often a Flutter/plugin issue
   - Consider reporting to the affected plugin's GitHub

## 📚 Reference

- [Apple Framework Bundle Structure](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html)
- [Flutter macOS Build Documentation](https://docs.flutter.dev/deployment/macos)

---

**Status:** Solution implemented and running
**Date:** February 11, 2026
**Build:** 1.14.0+100
