# Deep Linking in GrowERP Apps

This document explains how deep linking is configured and used in GrowERP applications.

## Overview

Deep linking allows users to open specific screens in your app via URLs. GrowERP apps support two types of deep links:

1. **Custom Scheme Links** (`growerp://`): Work immediately without server configuration
2. **HTTPS App Links/Universal Links**: Require server configuration but provide better user experience

## Supported Apps

Deep linking is currently configured for:
- **Admin** (`growerp://admin` or `https://admin.growerp.com`)
- **Support** (`growerp://support` or `https://support.growerp.com`)
- **Hotel** (`growerp://hotel` or `https://hotel.growerp.com`)

## How It Works

### Architecture

1. **DeepLinkService** (`growerp_core/lib/src/services/deep_link_service.dart`): 
   - Listens for incoming deep links using the `app_links` package
   - Extracts the navigation path from the URI
   - Integrates with GoRouter to navigate to the appropriate screen

2. **Dynamic Router Integration** (`growerp_core/lib/src/templates/dynamic_router_builder.dart`):
   - Accepts an optional `DeepLinkService` instance
   - Initializes the service with the router when the app starts

3. **Platform Configuration**:
   - **Android**: Intent filters in `AndroidManifest.xml`
   - **iOS**: URL schemes in `Info.plist`

### Deep Link Format

#### Custom Scheme (No server setup required)
```
growerp://admin/user
growerp://support/catalog/products
growerp://hotel/bookings
```

#### HTTPS Links (Requires server setup)
```
https://admin.growerp.com/user
https://support.growerp.com/catalog/products
https://hotel.growerp.com/bookings
```

## Testing Deep Links

### Android

#### Using ADB (Custom Scheme)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "growerp://admin/user" org.growerp.admin
```

#### Using ADB (HTTPS)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://admin.growerp.com/user" org.growerp.admin
```

### iOS

#### Using Simulator (Custom Scheme)
```bash
xcrun simctl openurl booted "growerp://admin/user"
```

#### Using Simulator (HTTPS)
```bash
xcrun simctl openurl booted "https://admin.growerp.com/user"
```

### Web Browser Testing

For custom schemes, create an HTML file:
```html
<!DOCTYPE html>
<html>
<body>
  <h1>Deep Link Test</h1>
  <a href="growerp://admin/user">Open Admin User Page</a>
  <a href="https://admin.growerp.com/user">Open Admin User Page (HTTPS)</a>
</body>
</html>
```

## Server Configuration for HTTPS Links

### Android App Links

1. **Get your app's SHA256 fingerprint**:
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/release.keystore -alias your-alias
```

2. **Create Digital Asset Links file** at `https://yourdomain.com/.well-known/assetlinks.json`:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "org.growerp.admin",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT_HERE"
    ]
  }
}]
```

3. **Verify the file is accessible**:
```bash
curl https://admin.growerp.com/.well-known/assetlinks.json
```

### iOS Universal Links

1. **Get your Team ID** from Apple Developer account

2. **Create Apple App Site Association file** at `https://yourdomain.com/.well-known/apple-app-site-association`:
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

**Important**: This file must be served with `Content-Type: application/json` and without `.json` extension.

3. **Verify the file is accessible**:
```bash
curl https://admin.growerp.com/.well-known/apple-app-site-association
```

## Adding Deep Linking to New Apps

To add deep linking to a new GrowERP app:

### 1. Android Configuration

Edit `android/app/src/main/AndroidManifest.xml` and add inside the `<activity>` tag:

```xml
<!-- Deep linking: HTTPS App Links -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="yourapp.growerp.com" />
</intent-filter>

<!-- Deep linking: Custom scheme fallback -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="growerp" android:host="yourapp" />
</intent-filter>
```

### 2. iOS Configuration

Edit `ios/Runner/Info.plist` and add before `</dict>`:

```xml
<!-- Deep linking configuration -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>org.growerp.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>growerp</string>
        </array>
    </dict>
</array>
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

### 3. App Code Integration

In your app's `main.dart`:

```dart
class _YourAppState extends State<YourApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... in your router configuration
    router = createDynamicAppRouter(
      [state.menuConfiguration!],
      config: DynamicRouterConfig(
        // ... other config
        deepLinkService: _deepLinkService,
      ),
    );
  }
}
```

## Common Routes

Here are some common routes you can deep link to:

- `/` - Home/Dashboard
- `/user` - User profile
- `/catalog/products` - Product catalog
- `/catalog/categories` - Category list
- `/orders` - Order list
- `/customers` - Customer list
- `/companies` - Company list

## Troubleshooting

### Android App Links Not Working

1. **Verify Digital Asset Links file**:
   - Check it's accessible at `https://yourdomain.com/.well-known/assetlinks.json`
   - Verify the SHA256 fingerprint matches your app's signing certificate
   - Use Google's [Statement List Generator and Tester](https://developers.google.com/digital-asset-links/tools/generator)

2. **Check App Link verification**:
```bash
adb shell pm get-app-links org.growerp.admin
```

3. **Clear app data and reinstall**:
```bash
adb shell pm clear org.growerp.admin
adb uninstall org.growerp.admin
# Reinstall the app
```

### iOS Universal Links Not Working

1. **Verify AASA file**:
   - Check it's accessible at `https://yourdomain.com/.well-known/apple-app-site-association`
   - Verify it's served with correct content type
   - Use Apple's [AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)

2. **Check Team ID and Bundle ID**:
   - Ensure they match your Apple Developer account
   - Verify in Xcode project settings

3. **Test on a real device**:
   - Universal Links don't always work in Simulator
   - Try sending the link via Messages or Notes app

### Custom Scheme Links Not Working

1. **Check manifest/plist configuration**:
   - Verify the scheme is correctly defined
   - Ensure `android:host` matches your app identifier

2. **Test with a simple HTML page**:
   - Create a test page with a link
   - Open in mobile browser and tap the link

## Security Considerations

1. **Validate Deep Link Paths**: Always validate that the user has permission to access the requested resource
2. **Handle Authentication**: Deep links should respect authentication state (handled automatically by GoRouter redirect)
3. **HTTPS Only for Production**: Use HTTPS App Links/Universal Links in production for security
4. **Rate Limiting**: Consider implementing rate limiting for deep link handling to prevent abuse

## Future Enhancements

Potential improvements to the deep linking system:

1. **Dynamic Link Parameters**: Support query parameters for filtering/sorting
2. **Analytics Integration**: Track deep link usage and conversion
3. **Deferred Deep Linking**: Handle links when app is not installed
4. **Branch/Firebase Integration**: Use third-party services for advanced features
5. **Deep Link Previews**: Show preview cards when sharing links

## References

- [Flutter Deep Linking Documentation](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [app_links Package](https://pub.dev/packages/app_links)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
