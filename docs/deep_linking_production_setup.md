# Production HTTPS Deep Links Setup Guide

## Overview

This guide shows you how to configure HTTPS deep links (App Links for Android, Universal Links for iOS) for production. This is **optional** - custom scheme links (`growerp://`) work without any server setup.

## Why Configure HTTPS Links?

**Benefits:**
- ✅ Better user experience (no "Open with..." dialog)
- ✅ More professional appearance
- ✅ Better security (HTTPS)
- ✅ SEO benefits (links are indexable)
- ✅ Works in more contexts (social media, email clients)

**When to use custom schemes instead:**
- ✅ During development/testing
- ✅ Internal tools
- ✅ Quick prototypes
- ✅ When you don't control the domain

## Prerequisites

Before you start, you need:
1. **Domain names** for your apps (e.g., `admin.growerp.com`, `support.growerp.com`)
2. **HTTPS enabled** on your domains (SSL certificate)
3. **Access to web server** to host configuration files
4. **Android release keystore** (for SHA256 fingerprint)
5. **Apple Developer account** (for Team ID)

## Step-by-Step Setup

### Part 1: Android App Links

#### Step 1: Get Your App's SHA256 Fingerprint

**For Debug Builds (Testing):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

**For Release Builds (Production):**
```bash
keytool -list -v -keystore /path/to/your/release.keystore \
  -alias your-key-alias
```

**Example Output:**
```
Certificate fingerprints:
SHA1: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42
SHA256: FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C
```

Copy the **SHA256** value (remove colons): `FAC61745DC0903786FB9EDE62A962B399F7348F0BB6F899B83326675913B9C`

#### Step 2: Create Digital Asset Links File

Create a file named `assetlinks.json` with this content:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "org.growerp.admin",
    "sha256_cert_fingerprints": [
      "FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C"
    ]
  }
}]
```

**For multiple apps on the same domain:**
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "org.growerp.admin",
      "sha256_cert_fingerprints": [
        "FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C"
      ]
    }
  },
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "org.growerp.support",
      "sha256_cert_fingerprints": [
        "FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C"
      ]
    }
  }
]
```

#### Step 3: Upload to Your Web Server

Upload the file to:
```
https://admin.growerp.com/.well-known/assetlinks.json
https://support.growerp.com/.well-known/assetlinks.json
https://hotel.growerp.com/.well-known/assetlinks.json
```

**Important Requirements:**
- ✅ Must be served over **HTTPS**
- ✅ Must be at **exact path** `/.well-known/assetlinks.json`
- ✅ Must have `Content-Type: application/json`
- ✅ Must be **publicly accessible** (no authentication)
- ✅ File size should be **< 1 MB**

#### Step 4: Configure Web Server

**For Nginx:**
```nginx
server {
    listen 443 ssl;
    server_name admin.growerp.com;
    
    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Serve assetlinks.json
    location /.well-known/assetlinks.json {
        alias /var/www/admin.growerp.com/.well-known/assetlinks.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    # Your other configuration...
}
```

**For Apache:**
```apache
<VirtualHost *:443>
    ServerName admin.growerp.com
    
    # SSL configuration
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    # Serve assetlinks.json
    Alias /.well-known/assetlinks.json /var/www/admin.growerp.com/.well-known/assetlinks.json
    
    <Location /.well-known/assetlinks.json>
        Header set Content-Type "application/json"
        Header set Access-Control-Allow-Origin "*"
    </Location>
    
    # Your other configuration...
</VirtualHost>
```

#### Step 5: Verify Android App Links

**Test the file is accessible:**
```bash
curl https://admin.growerp.com/.well-known/assetlinks.json
```

**Use Google's Statement List Generator:**
https://developers.google.com/digital-asset-links/tools/generator

**Verify on device:**
```bash
# Install your app
adb install app-release.apk

# Check app link verification status
adb shell pm get-app-links org.growerp.admin

# You should see: "verified" status
```

**Test the link:**
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://admin.growerp.com/user" \
  org.growerp.admin
```

---

### Part 2: iOS Universal Links

#### Step 1: Get Your Apple Team ID

1. Go to https://developer.apple.com/account
2. Sign in with your Apple Developer account
3. Your Team ID is shown in the top right (e.g., `ABCD123456`)

Or find it in Xcode:
1. Open your project in Xcode
2. Select your target
3. Go to "Signing & Capabilities"
4. Your Team ID is shown next to your team name

#### Step 2: Create Apple App Site Association File

Create a file named `apple-app-site-association` (NO .json extension):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABCD123456.org.growerp.admin",
        "paths": ["*"]
      }
    ]
  }
}
```

**For multiple apps:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABCD123456.org.growerp.admin",
        "paths": ["*"]
      },
      {
        "appID": "ABCD123456.org.growerp.support",
        "paths": ["*"]
      },
      {
        "appID": "ABCD123456.org.growerp.hotel",
        "paths": ["*"]
      }
    ]
  }
}
```

**Advanced path filtering:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABCD123456.org.growerp.admin",
        "paths": [
          "/user/*",
          "/catalog/*",
          "/orders/*",
          "NOT /admin/*"
        ]
      }
    ]
  }
}
```

#### Step 3: Upload to Your Web Server

Upload the file to:
```
https://admin.growerp.com/.well-known/apple-app-site-association
https://support.growerp.com/.well-known/apple-app-site-association
https://hotel.growerp.com/.well-known/apple-app-site-association
```

**Important Requirements:**
- ✅ Must be served over **HTTPS**
- ✅ Must be at **exact path** `/.well-known/apple-app-site-association`
- ✅ **NO .json extension**
- ✅ Must have `Content-Type: application/json`
- ✅ Must be **publicly accessible**
- ✅ File size should be **< 128 KB**

#### Step 4: Configure Web Server

**For Nginx:**
```nginx
server {
    listen 443 ssl;
    server_name admin.growerp.com;
    
    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Serve apple-app-site-association
    location /.well-known/apple-app-site-association {
        alias /var/www/admin.growerp.com/.well-known/apple-app-site-association;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    # Your other configuration...
}
```

**For Apache:**
```apache
<VirtualHost *:443>
    ServerName admin.growerp.com
    
    # SSL configuration
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    # Serve apple-app-site-association
    Alias /.well-known/apple-app-site-association /var/www/admin.growerp.com/.well-known/apple-app-site-association
    
    <Location /.well-known/apple-app-site-association>
        Header set Content-Type "application/json"
        Header set Access-Control-Allow-Origin "*"
    </Location>
    
    # Your other configuration...
</VirtualHost>
```

#### Step 5: Enable Associated Domains in Xcode

1. Open your project in Xcode
2. Select your target (e.g., Runner)
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Associated Domains"
6. Add your domains:
   - `applinks:admin.growerp.com`
   - `applinks:www.admin.growerp.com`

**Or edit the entitlements file directly:**
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:admin.growerp.com</string>
    <string>applinks:www.admin.growerp.com</string>
</array>
```

#### Step 6: Verify iOS Universal Links

**Test the file is accessible:**
```bash
curl https://admin.growerp.com/.well-known/apple-app-site-association
```

**Use Apple's AASA Validator:**
https://search.developer.apple.com/appsearch-validation-tool/

**Test on device:**
1. Install your app on a real iOS device (Universal Links don't always work in Simulator)
2. Send yourself an email or message with the link
3. Tap the link - it should open your app directly

**Debug on device:**
```bash
# Enable Universal Links debugging
xcrun simctl openurl booted "https://admin.growerp.com/user"

# Check console logs in Xcode for Universal Links messages
```

---

## Complete Example Setup

### Directory Structure on Web Server

```
/var/www/admin.growerp.com/
└── .well-known/
    ├── assetlinks.json                    (Android)
    └── apple-app-site-association         (iOS)

/var/www/support.growerp.com/
└── .well-known/
    ├── assetlinks.json                    (Android)
    └── apple-app-site-association         (iOS)

/var/www/hotel.growerp.com/
└── .well-known/
    ├── assetlinks.json                    (Android)
    └── apple-app-site-association         (iOS)
```

### Complete Nginx Configuration

```nginx
# Admin App
server {
    listen 443 ssl http2;
    server_name admin.growerp.com www.admin.growerp.com;
    
    ssl_certificate /etc/letsencrypt/live/admin.growerp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.growerp.com/privkey.pem;
    
    root /var/www/admin.growerp.com;
    
    # Android App Links
    location /.well-known/assetlinks.json {
        alias /var/www/admin.growerp.com/.well-known/assetlinks.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    # iOS Universal Links
    location /.well-known/apple-app-site-association {
        alias /var/www/admin.growerp.com/.well-known/apple-app-site-association;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    # Your app content...
}

# Support App
server {
    listen 443 ssl http2;
    server_name support.growerp.com www.support.growerp.com;
    
    ssl_certificate /etc/letsencrypt/live/support.growerp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/support.growerp.com/privkey.pem;
    
    root /var/www/support.growerp.com;
    
    location /.well-known/assetlinks.json {
        alias /var/www/support.growerp.com/.well-known/assetlinks.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    location /.well-known/apple-app-site-association {
        alias /var/www/support.growerp.com/.well-known/apple-app-site-association;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
}

# Hotel App
server {
    listen 443 ssl http2;
    server_name hotel.growerp.com www.hotel.growerp.com;
    
    ssl_certificate /etc/letsencrypt/live/hotel.growerp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hotel.growerp.com/privkey.pem;
    
    root /var/www/hotel.growerp.com;
    
    location /.well-known/assetlinks.json {
        alias /var/www/hotel.growerp.com/.well-known/assetlinks.json;
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }
    
    location /.well-known/apple-app-site-association {
        alias /var/www/hotel.growerp.com/.well-known/apple-app-site-association;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
}
```

---

## Troubleshooting

### Android App Links Not Working

**1. Verify the file is accessible:**
```bash
curl -I https://admin.growerp.com/.well-known/assetlinks.json
# Should return: Content-Type: application/json
```

**2. Check SHA256 fingerprint matches:**
```bash
keytool -list -v -keystore your-keystore.jks -alias your-alias
```

**3. Clear app data and reinstall:**
```bash
adb shell pm clear org.growerp.admin
adb uninstall org.growerp.admin
adb install app-release.apk
```

**4. Check verification status:**
```bash
adb shell pm get-app-links org.growerp.admin
```

**5. Manually verify domain:**
```bash
adb shell pm verify-app-links --re-verify org.growerp.admin
```

### iOS Universal Links Not Working

**1. Verify the file is accessible:**
```bash
curl -I https://admin.growerp.com/.well-known/apple-app-site-association
# Should return: Content-Type: application/json
```

**2. Use Apple's validator:**
https://search.developer.apple.com/appsearch-validation-tool/

**3. Check Team ID and Bundle ID:**
- Ensure they match your Apple Developer account
- Verify in Xcode project settings

**4. Test on real device:**
- Universal Links often don't work in Simulator
- Send link via Messages or Notes app

**5. Check entitlements:**
```bash
codesign -d --entitlements - YourApp.app
```

---

## Quick Setup Script

Save this as `setup-deep-links.sh`:

```bash
#!/bin/bash

# Configuration
DOMAIN="admin.growerp.com"
PACKAGE_NAME="org.growerp.admin"
TEAM_ID="ABCD123456"
KEYSTORE_PATH="~/.android/debug.keystore"
KEYSTORE_ALIAS="androiddebugkey"

# Get SHA256 fingerprint
echo "Getting SHA256 fingerprint..."
SHA256=$(keytool -list -v -keystore $KEYSTORE_PATH -alias $KEYSTORE_ALIAS -storepass android -keypass android 2>/dev/null | grep "SHA256:" | cut -d' ' -f3)
echo "SHA256: $SHA256"

# Create assetlinks.json
cat > assetlinks.json <<EOF
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "$PACKAGE_NAME",
    "sha256_cert_fingerprints": ["$SHA256"]
  }
}]
EOF

# Create apple-app-site-association
cat > apple-app-site-association <<EOF
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "$TEAM_ID.$PACKAGE_NAME",
      "paths": ["*"]
    }]
  }
}
EOF

echo "Files created successfully!"
echo "Upload these files to https://$DOMAIN/.well-known/"
```

---

## Summary

**For Production:**
1. ✅ Get SHA256 fingerprint (Android) and Team ID (iOS)
2. ✅ Create configuration files
3. ✅ Upload to `/.well-known/` on your domains
4. ✅ Configure web server with HTTPS
5. ✅ Verify files are accessible
6. ✅ Test on real devices

**Remember:**
- Custom scheme links work **immediately** without server setup
- HTTPS links provide better UX but require server configuration
- Both can coexist - use custom schemes for development, HTTPS for production

**Need help?** See the main documentation at `docs/deep_linking.md`
