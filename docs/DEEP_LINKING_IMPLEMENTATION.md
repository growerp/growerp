# Deep Linking Implementation Summary

## What Was Implemented

Deep linking has been successfully enabled across all GrowERP applications. This allows users to open specific screens in the app via URLs from emails, notifications, web links, or other apps.

## Changes Made

### 1. Core Package Updates

#### growerp_core Package
- **Added dependency**: `app_links: ^6.3.4` in `pubspec.yaml`
- **Created**: `DeepLinkService` class (`src/services/deep_link_service.dart`)
  - Listens for incoming deep links
  - Integrates with GoRouter for navigation
  - Supports both custom schemes and HTTPS URLs
- **Updated**: `dynamic_router_builder.dart`
  - Added `deepLinkService` parameter to `DynamicRouterConfig`
  - Initializes deep link service when router is created

### 2. Android Configuration

Updated `AndroidManifest.xml` for each app:
- **admin**: `packages/admin/android/app/src/main/AndroidManifest.xml`
- **support**: `packages/support/android/app/src/main/AndroidManifest.xml`
- **hotel**: `packages/hotel/android/app/src/main/AndroidManifest.xml`

Added two intent filters per app:
1. **HTTPS App Links** (with `android:autoVerify="true"`)
   - Supports URLs like `https://admin.growerp.com/user`
   - Requires server configuration (Digital Asset Links)
2. **Custom Scheme** (fallback)
   - Supports URLs like `growerp://admin/user`
   - Works immediately without server setup

### 3. iOS Configuration

Updated `Info.plist` for each app:
- **admin**: `packages/admin/ios/Runner/Info.plist`
- **support**: `packages/support/ios/Runner/Info.plist`
- **hotel**: `packages/hotel/ios/Runner/Info.plist`

Added:
- `CFBundleURLTypes` for custom URL scheme (`growerp://`)
- `FlutterDeepLinkingEnabled` flag

### 4. Application Integration

Updated `main.dart` for admin app (template for other apps):
- Added `DeepLinkService` instance
- Passed service to `DynamicRouterConfig`
- Proper disposal in `dispose()` method

### 5. Documentation

Created comprehensive documentation:
- **Workflow**: `.agent/workflows/enable-deep-linking.md`
  - Step-by-step implementation guide
  - Server configuration instructions
- **Deep Linking Guide**: `docs/deep_linking.md`
  - Complete reference documentation
  - Testing procedures
  - Troubleshooting guide
  - Security considerations

### 6. Testing Tools

Created `test_deep_link.sh`:
- Interactive script for testing deep links
- Supports both Android and iOS
- Tests custom scheme and HTTPS links
- Validates device/emulator connectivity

## Supported Deep Link Formats

### Custom Scheme (Works Immediately)
```
growerp://admin/user
growerp://support/catalog/products
growerp://hotel/bookings
```

### HTTPS Links (Requires Server Setup)
```
https://admin.growerp.com/user
https://support.growerp.com/catalog/products
https://hotel.growerp.com/bookings
```

## How to Test

### Quick Test with Custom Scheme

**Android:**
```bash
cd flutter
./test_deep_link.sh -p android -a admin -r /user
```

**iOS:**
```bash
cd flutter
./test_deep_link.sh -p ios -a admin -r /user
```

### Manual Testing

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "growerp://admin/user" org.growerp.admin
```

**iOS:**
```bash
xcrun simctl openurl booted "growerp://admin/user"
```

## Next Steps for Production

### For HTTPS App Links (Android)

1. **Get SHA256 fingerprint** of your release keystore:
```bash
keytool -list -v -keystore /path/to/release.keystore -alias your-alias
```

2. **Create Digital Asset Links file** at `https://admin.growerp.com/.well-known/assetlinks.json`:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "org.growerp.admin",
    "sha256_cert_fingerprints": ["YOUR_SHA256_FINGERPRINT"]
  }
}]
```

3. **Verify** the file is accessible and valid

### For Universal Links (iOS)

1. **Get your Team ID** from Apple Developer account

2. **Create AASA file** at `https://admin.growerp.com/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.org.growerp.admin",
      "paths": ["*"]
    }]
  }
}
```

3. **Verify** the file is served correctly (no .json extension, correct content-type)

## Architecture

```
User clicks link (growerp://admin/user)
         ↓
OS recognizes app can handle this URL
         ↓
App launches/comes to foreground
         ↓
DeepLinkService receives the URI
         ↓
Extracts path (/user) from URI
         ↓
GoRouter navigates to the path
         ↓
User sees the requested screen
```

## Benefits

1. **Better User Experience**: Direct navigation to specific content
2. **Marketing**: Track campaign effectiveness with deep links
3. **Email Integration**: Password reset, verification links
4. **Push Notifications**: Open specific screens from notifications
5. **Cross-App Navigation**: Link between different GrowERP apps
6. **Web Integration**: Seamless transition from web to mobile

## Security Notes

- Deep links respect authentication state (handled by GoRouter redirect)
- Unauthenticated users are redirected to login
- Always validate user permissions for accessed resources
- HTTPS links provide better security than custom schemes

## Files Modified

```
growerp_core/
├── pubspec.yaml (added app_links dependency)
├── lib/
│   ├── growerp_core.dart (exported DeepLinkService)
│   └── src/
│       ├── services/
│       │   └── deep_link_service.dart (NEW)
│       └── templates/
│           └── dynamic_router_builder.dart (updated)

admin/
├── android/app/src/main/AndroidManifest.xml (updated)
├── ios/Runner/Info.plist (updated)
└── lib/main.dart (updated)

support/
├── android/app/src/main/AndroidManifest.xml (updated)
└── ios/Runner/Info.plist (updated)

hotel/
├── android/app/src/main/AndroidManifest.xml (updated)
└── ios/Runner/Info.plist (updated)

flutter/
├── docs/deep_linking.md (NEW)
├── test_deep_link.sh (NEW)
└── .agent/workflows/enable-deep-linking.md (NEW)
```

## Common Routes

The following routes are available for deep linking (varies by app):

- `/` - Home/Dashboard
- `/user` - User profile
- `/catalog/products` - Product catalog
- `/catalog/categories` - Category list
- `/orders` - Order list
- `/customers` - Customer list
- `/companies` - Company list
- `/inventory` - Inventory management
- `/accounting` - Accounting dashboard

## Troubleshooting

If deep links aren't working:

1. **Check app is installed** on the device/emulator
2. **Verify route exists** in the app's menu configuration
3. **Test custom scheme first** (doesn't require server setup)
4. **Check logs** for DeepLinkService debug messages
5. **For HTTPS links**: Verify server configuration is correct
6. **Clear app data** and reinstall if necessary

See `docs/deep_linking.md` for detailed troubleshooting steps.

## References

- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [app_links Package](https://pub.dev/packages/app_links)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
