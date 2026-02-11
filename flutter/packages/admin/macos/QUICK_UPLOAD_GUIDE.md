# Quick Reference: macOS App Store Upload

## ✅ Current Status

**Build completed successfully!**

- **App**: `build/macos/Build/Products/Release/admin.app` ✓
- **dSYM**: `build/macos/Build/Products/Release/admin.app.dSYM` ✓
- **Version**: 1.14.0+100
- **Bundle ID**: org.growerp.admin
- **Team ID**: P64T65C668
- **Xcode workspace**: Opened and ready

## 🚀 Quick Start - Upload Now

### Option A: Complete Build & Archive (Recommended)

Run the automated script:

```bash
cd /Users/hans/growerp/flutter/packages/admin/macos
./build-for-appstore.sh
```

This will:
1. Clean previous builds
2. Get Flutter dependencies
3. Build Flutter release
4. Update CocoaPods
5. Create Xcode archive with dSYM
6. Open Xcode Organizer

Then follow the prompts to upload.

### Option B: Manual Xcode Archive

Since the Xcode workspace is already open:

1. In Xcode, select **Runner** scheme and **Any Mac** destination
2. **Product** → **Archive** (⌘⇧B)
3. Wait for archiving to complete
4. In Organizer, click **Distribute App**
5. Choose **App Store Connect**
6. Select **Upload**
7. Review and upload (dSYMs will be included automatically)

### Option C: Use Current Build

The current Flutter build is ready. To create an archive from it:

```bash
cd /Users/hans/growerp/flutter/packages/admin/macos
./build-for-appstore.sh
```

Or manually in Xcode (already open).

## 📤 Upload Only (After Archive Created)

If you already have an archive:

```bash
cd /Users/hans/growerp/flutter/packages/admin/macos
./upload-to-appstore.sh
```

Choose your preferred upload method:
1. Transporter app (easiest)
2. Command line with altool
3. Xcode Organizer

## 🔍 Verify dSYM

Check the dSYM UUIDs match:

```bash
cd /Users/hans/growerp/flutter/packages/admin/build/macos/Build/Products/Release
dwarfdump --uuid admin.app.dSYM
```

## ⚠️ Troubleshooting

### Missing dSYM Error

If App Store Connect shows missing dSYM with UUIDs like:
- `03B6A1A2-5E7D-3739-8E76-9D012056D4A4`
- `66EA13FF-F635-3458-A0B9-E1F9424A00B0`

**Solution**: You need the exact archive used for that build. Either:
1. Find the original archive on this Mac or teammate's Mac
2. Or upload a NEW build version (increment build number)

The current build will have NEW UUIDs, which won't match old builds.

### Code Signing Issues

Check your certificates:

```bash
security find-identity -v -p codesigning
```

You should see "Apple Distribution: Johannes Bakker (P64T65C668)"

### Archive Not Found

If archive creation fails:
1. Open Xcode manually
2. Check Product → Scheme → Edit Scheme
3. Ensure Archive uses Release configuration
4. Try Product → Clean Build Folder first

## 📋 Pre-Upload Checklist

- [ ] Version bumped: `pubspec.yaml` → version: 1.14.0+100
- [ ] Valid code signing certificate
- [ ] App Store Connect record exists
- [ ] All metadata complete in App Store Connect
- [ ] Privacy policy URL updated
- [ ] Screenshots uploaded
- [ ] Tested on real Mac hardware

## 🔐 Code Signing Status

Current valid identities:
- ✓ **Apple Distribution**: Johannes Bakker (P64T65C668)
- ✓ **3rd Party Mac Developer**: Johannes Bakker (P64T65C668)
- ✓ **Apple Development**: Johannes Bakker (PADQ53UC4P)

## 📱 App Info

- **Name**: GrowERP Admin
- **Bundle ID**: org.growerp.admin
- **Version**: 1.14.0
- **Build**: 100
- **Platform**: macOS
- **Architecture**: Universal (Apple Silicon + Intel)

## 🎯 After Upload

1. **Wait**: Processing takes 15-30 minutes
2. **Check**: App Store Connect → My Apps → Activity
3. **TestFlight**: Build appears automatically
4. **Test**: Internal testing first
5. **Submit**: When ready, submit for App Review

## 🔗 Useful Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://appstoreconnect.apple.com/apps)
- [Certificate Management](https://developer.apple.com/account/resources/certificates)
- [App-Specific Passwords](https://appleid.apple.com/account/manage)

## 💡 Tips

- **Keep archives**: Don't delete old archives until no longer needed for crash symbolication
- **Backup dSYMs**: Copy dSYMs to safe storage after each upload
- **Increment builds**: Always increment build number for new uploads
- **Test first**: Use TestFlight internal testing before external

---

**Built**: February 11, 2026  
**Location**: `/Users/hans/growerp/flutter/packages/admin/`  
**Workspace**: `macos/Runner.xcworkspace` (currently open)
