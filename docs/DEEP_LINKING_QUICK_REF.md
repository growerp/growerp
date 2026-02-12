# Deep Linking Quick Reference

## ✅ What's Been Done

Deep linking is now **fully enabled** for GrowERP apps (admin, support, hotel).

## 🚀 Quick Start

### Test Custom Scheme Links (Works Now!)

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

### Example Deep Links

```
growerp://admin/user
growerp://support/catalog/products
growerp://hotel/bookings
growerp://admin/orders
growerp://support/customers
```

## 📱 How It Works

1. User clicks a deep link (e.g., `growerp://admin/user`)
2. OS launches your app
3. DeepLinkService receives the link
4. GoRouter navigates to `/user`
5. User sees the requested screen

## 🔧 For Other Apps

To add deep linking to support, hotel, or other apps, update their `main.dart`:

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
    // In your router config:
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

## 🌐 Production Setup (HTTPS Links)

### Android App Links

1. Get SHA256 fingerprint:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

2. Create `https://admin.growerp.com/.well-known/assetlinks.json`:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "org.growerp.admin",
    "sha256_cert_fingerprints": ["YOUR_SHA256_HERE"]
  }
}]
```

### iOS Universal Links

1. Create `https://admin.growerp.com/.well-known/apple-app-site-association`:
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

## 📚 Documentation

- **Full Guide**: `docs/deep_linking.md`
- **Implementation Details**: `DEEP_LINKING_IMPLEMENTATION.md`
- **Workflow**: `.agent/workflows/enable-deep-linking.md`

## 🐛 Troubleshooting

**App doesn't open?**
1. Check app is installed
2. Verify route exists
3. Try custom scheme first (`growerp://`)
4. Check device/emulator is connected

**HTTPS links not working?**
1. Custom schemes work without server setup
2. HTTPS requires server configuration
3. See full docs for setup instructions

## 🎯 Common Routes

- `/` - Dashboard
- `/user` - User profile
- `/catalog/products` - Products
- `/orders` - Orders
- `/customers` - Customers
- `/companies` - Companies

## 💡 Use Cases

- Email verification links
- Password reset flows
- Marketing campaigns
- Push notifications
- Shared content
- Cross-app navigation

---

**Need help?** See `docs/deep_linking.md` for complete documentation.
