---
description: Enable deep linking in GrowERP apps
---

# Enable Deep Linking in GrowERP Apps

This workflow enables deep linking (App Links for Android and Universal Links for iOS) across all GrowERP applications.

## Overview

Deep linking allows users to open specific screens in your app via URLs. This is essential for:
- Email verification links
- Password reset flows
- Shared content links
- Marketing campaigns
- Push notification actions

## Implementation Steps

### 1. Add app_links Package

Add `app_links` to `growerp_core/pubspec.yaml`:
```yaml
dependencies:
  app_links: ^6.3.4
```

### 2. Configure Android App Links

For each app (admin, support, hotel, health, freelance), update `android/app/src/main/AndroidManifest.xml`:

Add intent filters inside the `<activity>` tag:
```xml
<!-- Deep linking intent filter -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Replace with your domain -->
    <data android:scheme="https" android:host="admin.growerp.com" />
    <data android:scheme="https" android:host="www.admin.growerp.com" />
</intent-filter>
<!-- Custom scheme for fallback -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="growerp" android:host="admin" />
</intent-filter>
```

### 3. Configure iOS Universal Links

For each app, update `ios/Runner/Info.plist`:

Add before the closing `</dict>`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>org.growerp.admin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>growerp</string>
        </array>
    </dict>
</array>
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

### 4. Create Deep Link Service

Create `growerp_core/lib/src/services/deep_link_service.dart` to handle incoming links.

### 5. Integrate with GoRouter

Update the router configuration to handle deep links and navigate to the appropriate routes.

### 6. Host Digital Asset Links (Android)

Host a file at `https://yourdomain.com/.well-known/assetlinks.json`:
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

Get your SHA256 fingerprint:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 7. Host Apple App Site Association (iOS)

Host a file at `https://yourdomain.com/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.org.growerp.admin",
        "paths": ["*"]
      }
    ]
  }
}
```

### 8. Test Deep Links

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://admin.growerp.com/user" org.growerp.admin
adb shell am start -W -a android.intent.action.VIEW -d "growerp://admin/user"
```

**iOS:**
```bash
xcrun simctl openurl booted "https://admin.growerp.com/user"
xcrun simctl openurl booted "growerp://admin/user"
```

## Notes

- Each app needs its own domain/subdomain for App Links
- Custom schemes (growerp://) work without server configuration
- Universal Links require HTTPS and proper server configuration
- Test both authenticated and unauthenticated deep link scenarios
