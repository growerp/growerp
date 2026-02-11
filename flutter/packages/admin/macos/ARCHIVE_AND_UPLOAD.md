# macOS App Archive and Upload Guide

This guide walks you through archiving and uploading the GrowERP Admin macOS app to the App Store.

## ✅ Build Completed Successfully

The release build has been completed at:
- **App**: `build/macos/Build/Products/Release/admin.app`
- **dSYM**: `build/macos/Build/Products/Release/admin.app.dSYM`

## 📦 Steps to Archive and Upload

### Option 1: Using Xcode (Recommended)

1. **Open the Xcode workspace** (already opened):
   ```bash
   open macos/Runner.xcworkspace
   ```

2. **Select the correct scheme**:
   - At the top of Xcode, select **"Runner"** scheme
   - Select **"Any Mac (Apple Silicon, Intel)"** as the destination

3. **Archive the app**:
   - Go to **Product** → **Archive** (or press `⌘ + Shift + B`)
   - Wait for the archive to complete (this may take a few minutes)

4. **Upload to App Store Connect**:
   - When archiving completes, the **Organizer** window will open automatically
   - Select your archive from the list
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Follow the wizard:
     - Upload method: **"Upload"**
     - App Store Connect options: Keep defaults (include symbols)
     - Re-sign: Use automatic signing
     - Review and upload

5. **Verify dSYM Upload**:
   - The wizard will automatically include the dSYM files
   - After upload, you can verify in App Store Connect → TestFlight → Build → Build Metadata

### Option 2: Using Command Line with `xcodebuild`

```bash
# 1. Archive the app
cd /Users/hans/growerp/flutter/packages/admin/macos
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -archivePath build/Runner.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# 2. Export for App Store
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# 3. Upload with altool or Transporter
xcrun altool --upload-app \
  --type macos \
  --file "build/export/admin.pkg" \
  --username "your-apple-id@example.com" \
  --password "@keychain:AC_PASSWORD"
```

## 🔍 Troubleshooting dSYM Issues

If you encounter "Missing dSYM" warnings:

### Check Current dSYM UUIDs

```bash
cd build/macos/Build/Products/Release
dwarfdump --uuid admin.app.dSYM
dwarfdump --uuid admin.app/Contents/MacOS/admin
```

The UUIDs from both commands should match. These are the UUIDs that App Store Connect expects.

### Verify Build Settings

The project is already configured correctly:
- ✅ **DEBUG_INFORMATION_FORMAT** = `dwarf-with-dsym` for Release
- ✅ dSYM files are generated automatically during build

### Manual dSYM Upload

If needed, you can manually upload dSYM files:

1. **Find your archive**:
   - Open Xcode → Window → Organizer → Archives
   - Right-click your archive → Show in Finder
   - Right-click the `.xcarchive` → Show Package Contents
   - Navigate to `dSYMs/` folder

2. **Upload to App Store Connect**:
   - Go to App Store Connect → TestFlight → Select Build
   - Scroll to "Build Metadata" section
   - Upload the `admin.app.dSYM` folder

3. **For crash reporting services**:
   ```bash
   # Find the dSYM
   cd ~/Library/Developer/Xcode/Archives
   find . -name "*.dSYM" -path "*admin*"
   
   # Upload to your service (e.g., Firebase Crashlytics)
   # Follow your service's specific upload instructions
   ```

## 📋 Pre-Upload Checklist

- [ ] Version number updated in `pubspec.yaml` (currently: 1.14.0+100)
- [ ] Code signing certificate is valid
- [ ] App Store Connect record exists
- [ ] All required app information filled in App Store Connect
- [ ] Privacy policy and terms of service URLs are up to date
- [ ] Screenshot and app preview assets uploaded
- [ ] Test the app on real macOS hardware
- [ ] Archive includes dSYM files

## 🔐 Code Signing

Ensure your Mac has:
- Valid Apple Distribution certificate
- Valid Mac App Store provisioning profile
- Keychain Access has the certificates unlocked

Check with:
```bash
security find-identity -v -p codesigning
```

## 📱 App Information

- **Bundle ID**: Check in Xcode project settings
- **Version**: 1.14.0
- **Build Number**: 100
- **Min macOS Version**: Check deployment target in Xcode

## 🎯 Next Steps After Upload

1. Wait for processing (15-30 minutes typically)
2. Check TestFlight for the new build
3. Submit for internal/external testing
4. Once tested, submit for App Review
5. Monitor App Store Connect for review status

## 📞 Support

If you encounter issues:
- Check App Store Connect → Activity for processing status
- Review rejection reasons (if any) in Resolution Center
- Verify code signing and entitlements
- Check that all required metadata is complete

---

**Last Build**: February 11, 2026
**Build Location**: `/Users/hans/growerp/flutter/packages/admin/build/macos/Build/Products/Release/`
