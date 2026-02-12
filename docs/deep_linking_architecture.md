# Deep Linking Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Deep Link Sources                      │
        │  • Email (verification, password reset) │
        │  • SMS / Push Notifications             │
        │  • Web Browser                          │
        │  • QR Codes                             │
        │  • Other Apps                           │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  Deep Link Formats                      │
        │                                         │
        │  Custom Scheme:                         │
        │  growerp://admin/user                   │
        │  growerp://support/customers            │
        │  growerp://hotel/orders                 │
        │                                         │
        │  HTTPS (Production):                    │
        │  https://admin.growerp.com/user         │
        │  https://support.growerp.com/customers  │
        │  https://hotel.growerp.com/orders       │
        └─────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OPERATING SYSTEM                              │
│                                                                  │
│  Android:                      iOS:                              │
│  • Intent Filters             • URL Schemes                      │
│  • App Links (autoVerify)     • Universal Links                  │
│  • Digital Asset Links        • AASA File                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  main.dart                                               │  │
│  │  • Creates DeepLinkService instance                      │  │
│  │  • Passes to DynamicRouterConfig                         │  │
│  │  • Disposes on app close                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DeepLinkService (growerp_core)                          │  │
│  │  • Listens via app_links package                         │  │
│  │  • Handles initial link (app opened via link)            │  │
│  │  • Handles stream (app running, new link received)       │  │
│  │  • Extracts navigation path from URI                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GoRouter                                                │  │
│  │  • Receives path from DeepLinkService                    │  │
│  │  • Checks authentication (redirect if needed)            │  │
│  │  • Matches route from menu configuration                 │  │
│  │  • Navigates to appropriate screen                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DisplayMenuItem / Screen Widget                         │  │
│  │  • Renders the requested screen                          │  │
│  │  • User sees the content they clicked                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Example

```
User clicks: growerp://admin/user
│
├─ Android Intent System
│  └─ Matches: <data android:scheme="growerp" android:host="admin" />
│
├─ iOS URL Scheme Handler  
│  └─ Matches: CFBundleURLSchemes: ["growerp"]
│
└─ App Launches/Activates
   │
   ├─ DeepLinkService.initialize()
   │  │
   │  ├─ getInitialLink() → growerp://admin/user
   │  │  └─ _handleDeepLink(uri)
   │  │
   │  └─ uriLinkStream.listen()
   │     └─ Future links handled here
   │
   ├─ _extractPath(uri)
   │  │
   │  ├─ Input: growerp://admin/user
   │  └─ Output: /user
   │
   ├─ GoRouter.go('/user')
   │  │
   │  ├─ Check AuthBloc state
   │  │  ├─ Authenticated? → Continue
   │  │  └─ Not authenticated? → Redirect to '/'
   │  │
   │  └─ Match route in menu configuration
   │     └─ Find MenuItem with route='/user'
   │
   └─ Navigate to UserDialog
      └─ User sees their profile ✨
```

## Component Interaction

```
┌─────────────────┐
│   app_links     │ (Package)
│   Package       │
└────────┬────────┘
         │ Provides URI stream
         ▼
┌─────────────────┐
│ DeepLinkService │ (growerp_core/services)
│                 │
│ • initialize()  │
│ • dispose()     │
│ • _handleLink() │
└────────┬────────┘
         │ Calls router.go(path)
         ▼
┌─────────────────┐
│    GoRouter     │ (go_router package)
│                 │
│ • routes[]      │
│ • redirect()    │
│ • onException() │
└────────┬────────┘
         │ Navigates to route
         ▼
┌─────────────────┐
│ DisplayMenuItem │ (growerp_core/templates)
│                 │
│ • Renders UI    │
│ • Shows content │
└─────────────────┘
```

## Configuration Files

```
Android (AndroidManifest.xml)
├─ HTTPS App Links
│  └─ <intent-filter android:autoVerify="true">
│     └─ <data android:scheme="https" android:host="admin.growerp.com" />
│
└─ Custom Scheme
   └─ <intent-filter>
      └─ <data android:scheme="growerp" android:host="admin" />

iOS (Info.plist)
├─ Custom URL Scheme
│  └─ CFBundleURLTypes
│     └─ CFBundleURLSchemes: ["growerp"]
│
└─ Universal Links
   └─ FlutterDeepLinkingEnabled: true
```

## Server Configuration (Production)

```
Android App Links
https://admin.growerp.com/.well-known/assetlinks.json
└─ {
     "relation": ["delegate_permission/common.handle_all_urls"],
     "target": {
       "namespace": "android_app",
       "package_name": "org.growerp.admin",
       "sha256_cert_fingerprints": ["..."]
     }
   }

iOS Universal Links
https://admin.growerp.com/.well-known/apple-app-site-association
└─ {
     "applinks": {
       "details": [{
         "appID": "TEAM_ID.org.growerp.admin",
         "paths": ["*"]
       }]
     }
   }
```

## State Management

```
App Lifecycle States:

1. App Not Running
   └─ Deep link clicked
      └─ OS launches app
         └─ getInitialLink() receives URI
            └─ Navigate to path

2. App Running (Background)
   └─ Deep link clicked
      └─ OS brings app to foreground
         └─ uriLinkStream emits URI
            └─ Navigate to path

3. App Running (Foreground)
   └─ Deep link clicked
      └─ uriLinkStream emits URI
         └─ Navigate to path
```

## Authentication Flow

```
Deep Link Received
│
├─ GoRouter.redirect()
│  │
│  ├─ Check AuthBloc.state
│  │  │
│  │  ├─ Authenticated
│  │  │  └─ return null (allow navigation)
│  │  │
│  │  └─ Not Authenticated
│  │     └─ return '/' (redirect to login)
│  │
│  └─ User logs in
│     └─ AuthBloc emits authenticated state
│        └─ Can manually navigate to original path
│           (Future: Store original path for post-login redirect)
```

## Testing Flow

```
Development Testing
│
├─ Custom Scheme (No server needed)
│  │
│  ├─ Android: adb shell am start -d "growerp://admin/user"
│  └─ iOS: xcrun simctl openurl booted "growerp://admin/user"
│
└─ HTTPS (Requires server setup)
   │
   ├─ Android: adb shell am start -d "https://admin.growerp.com/user"
   └─ iOS: xcrun simctl openurl booted "https://admin.growerp.com/user"

Production Testing
│
├─ Send test email with deep link
├─ Create QR code with deep link
├─ Share link via messaging app
└─ Click link from web browser
```

---

This architecture provides:
✅ Seamless user experience
✅ Platform-native deep linking
✅ Flexible routing
✅ Authentication protection
✅ Easy testing and debugging
