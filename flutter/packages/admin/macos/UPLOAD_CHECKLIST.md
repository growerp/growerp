# macOS App Store Upload - Complete Checklist

## ✅ Pre-Upload Checklist

- [ ] Version number incremented in `pubspec.yaml`
- [ ] Code signing certificates valid
- [ ] App Store Connect record exists
- [ ] All metadata complete in App Store Connect
- [ ] Privacy policy URL updated
- [ ] Screenshots uploaded (if required)
- [ ] Tested on real Mac hardware

## 🔧 Build Process (with Framework Fixes)

### Automated (Recommended)

```bash
cd /Users/hans/growerp/flutter/packages/admin
./macos/archive-with-fixes.sh
```

This handles:
- ✅ Clean build
- ✅ Dependency resolution
- ✅ Flutter build
- ✅ Framework structure fixes
- ✅ Xcode archive creation
- ✅ Framework validation

### Manual Steps (if needed)

```bash
# 1. Clean
flutter clean

# 2. Dependencies
flutter pub get
cd macos && pod install && cd ..

# 3. Build
flutter build macos --release

# 4. Fix frameworks
./macos/fix-frameworks.sh

# 5. Archive in Xcode
open macos/Runner.xcworkspace
# Then: Product → Archive
```

## 📤 Upload Process

### Option 1: Xcode Organizer (Easiest)

1. Open Organizer:
   ```bash
   open macos/Runner.xcworkspace
   ```
   Then: Window → Organizer

2. Select latest archive

3. Click **"Distribute App"**

4. Choose **"App Store Connect"**

5. Select **"Upload"**

6. Click through the dSYM warning (press "Done" twice)

7. Complete upload

### Option 2: Export then Transporter

```bash
./macos/export-archive.sh
```

This will:
- Export the archive
- Offer to open Transporter
- Or provide altool command

### Option 3: Command Line

```bash
# Export
./macos/export-archive.sh

# Upload with altool
xcrun altool --upload-app \
  --type macos \
  --file "build/export/admin.pkg" \
  --username "your-apple-id@example.com" \
  --password "@keychain:AC_PASSWORD"
```

## ⚠️ Common Issues & Solutions

### Issue: "Malformed Framework" Error

**Solution:** Already fixed by `archive-with-fixes.sh`

If it persists:
```bash
# Manually fix frameworks
./macos/fix-frameworks.sh

# Then re-archive
./macos/archive-with-fixes.sh
```

### Issue: dSYM UUID Warning

**Solution:** This is about an OLD build. Just click "Done" twice.

The warning shows:
```
UUIDs [03B6A1A2-5E7D-3739-8E76-9D012056D4A4, 66EA13FF-F635-3458-A0B9-E1F9424A00B0]
```

These are from a previous upload. Your NEW build has different UUIDs (which is correct).

**Action:** Ignore and continue.

### Issue: Code Signing Failed

**Check certificates:**
```bash
security find-identity -v -p codesigning
```

You need: "Apple Distribution: Johannes Bakker (P64T65C668)"

**Fix:**
1. Open Xcode
2. Preferences → Accounts
3. Download Manual Profiles
4. Try again

### Issue: "No package found to upload"

**Solution:**
```bash
# Make sure export succeeded
ls -la build/export/

# Should contain admin.pkg or admin.app
```

### Issue: CocoaPods Warning

The warning about base configuration is harmless. Your build will work fine.

To silence it, add to `macos/Runner/Configs/Release.xcconfig`:
```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
```

## 📊 After Upload

### Processing Timeline

1. **Upload completes** ← You are here after clicking "Done"
2. **Processing** (15-30 minutes)
   - Apple scans for malware
   - Validates app structure
   - Extracts metadata
3. **Appears in TestFlight** (automatic)
4. **Ready for internal testing** (immediate)
5. **Ready for external testing** (after adding testers)
6. **Submit for App Review** (when ready)

### Monitor Status

- **App Store Connect** → My Apps → admin → Activity
- Look for your build: 1.14.0 (100)
- Status shows: Processing → Ready to Submit

### If Processing Fails

Common failures:
- **Malformed framework** → Run `archive-with-fixes.sh` again
- **Missing entitlements** → Check in Xcode signing settings
- **Invalid provisioning** → Regenerate in developer portal
- **Binary validation** → Check architecture (should be universal)

## 🎯 Next Steps After Processing

1. **Test in TestFlight**
   - Add internal testers
   - Install and test thoroughly
   - Check for crashes

2. **Add Build to Release**
   - App Store Connect → App Store → Prepare for Submission
   - Select build 1.14.0 (100)
   - Complete all required fields

3. **Submit for Review**
   - Review submission checklist
   - Answer App Review questions
   - Submit

4. **Monitor Review Status**
   - Typical review time: 1-3 days
   - Check email for updates
   - Respond to any questions promptly

## 📱 App Information

- **Bundle ID:** org.growerp.admin
- **Version:** 1.14.0
- **Build:** 100
- **Team ID:** P64T65C668
- **Architectures:** x86_64, arm64 (Universal)

## 🔗 Quick Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://appstoreconnect.apple.com/apps)
- [Certificates](https://developer.apple.com/account/resources/certificates)
- [Support](https://developer.apple.com/support/app-store/)

## 💾 Scripts Reference

| Script | Purpose |
|--------|---------|
| `archive-with-fixes.sh` | **Main script** - builds and archives with framework fixes |
| `export-archive.sh` | Export archive for upload |
| `fix-frameworks.sh` | Fix framework structures in existing build |
| `build-with-fixes.sh` | Build with framework fixes (no archive) |
| `upload-old-dsym.sh` | Upload old dSYM if needed (usually not) |
| `find-dsym.sh` | Search for dSYM by UUID |

## 🆘 Getting Help

If stuck:
1. Check `FRAMEWORK_FIX_GUIDE.md` for framework issues
2. Check `DSYM_WARNING_EXPLAINED.md` for dSYM warnings
3. Check `QUICK_UPLOAD_GUIDE.md` for general upload help
4. Check App Store Connect for specific error messages

---

**Status:** Build in progress
**Current Version:** 1.14.0+100
**Last Updated:** February 11, 2026
