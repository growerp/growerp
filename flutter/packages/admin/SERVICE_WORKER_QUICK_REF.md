# Flutter Admin Service Worker - Quick Reference

## ✅ What Was Fixed

**Problem:** Service worker registration wasn't working when clicking the Admin link in the navbar.

**Solution:** 
1. Fixed base href in `/admin/index.html` to use `/admin/` instead of `/`
2. Added service worker registration directly in the admin app
3. Updated deployment scripts to automatically apply these fixes
4. Improved navbar styling

## 🚀 How to Use

### For Users
Click the **Admin** link (with gear icon) in the navbar to access the Flutter admin application.

### For Developers

**Deploy after building:**
```bash
cd flutter/packages/admin
./build-and-deploy-web.sh
```

**Deploy existing build:**
```bash
cd flutter/packages/admin
./deploy-web-to-moqui.sh
```

## 🧪 Testing

**Quick Test:**
1. Start Moqui server
2. Visit: `http://localhost:8080/admin/service-worker-test.html`
3. Click "Check Status" - should show service worker registered

**Full Test:**
1. Click "Admin" in navbar
2. Open browser DevTools (F12)
3. Go to Application > Service Workers
4. Should see service worker active with scope `/admin/`

## 📁 Key Files

| File | Purpose |
|------|---------|
| `root.html.ftl` | **Early service worker registration** (main store) |
| `/admin/index.html` | Main entry point with fallback SW registration |
| `/admin/flutter_service_worker.js` | The service worker file |
| `/admin/service-worker-test.html` | Test page for debugging |
| `navbar.html.ftl` | Updated navbar with Admin link |
| `admin.xml` | Moqui screen that serves the admin app |

## 🔧 Architecture

```
User visits store at /
    ↓
root.html.ftl loads
    ↓
Service worker registration starts IMMEDIATELY
    ↓
Service worker begins installing in background
    ↓
User clicks "Admin" in navbar
    ↓
Navigate to /admin/ (served by admin.xml screen)
    ↓
Load /admin/index.html
    ↓
<base href="/admin/"> ensures assets load from /admin/
    ↓
Flutter bootstrap finds already-registered service worker ✨
    ↓
Service worker already active and ready!
    ↓
Flutter app loads FAST with offline support
```

**Single Registration Strategy:**
- **Only in root.html.ftl**: Early registration when main store loads
- **NOT in admin/index.html**: Avoids duplicate registration timeout issues
- **Flutter bootstrap**: Automatically finds and uses pre-registered SW
- Result: SW is ready **before** user clicks Admin link, no timeouts!

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| 404 on service worker | Run `./deploy-web-to-moqui.sh` |
| Assets not loading | Check base href is `/admin/` in index.html |
| Service worker not registering | Visit test page to check status |
| Old version cached | Clear cache or hard refresh (Ctrl+Shift+R) |

## 📝 Notes

- Service worker only works over HTTPS (or localhost)
- First visit requires network; subsequent visits work offline
- Service worker scope is limited to `/admin/*` paths only
- Deployment scripts are idempotent (safe to run multiple times)

## 🔗 Related Documentation

- Full deployment guide: `flutter/packages/admin/DEPLOY_WEB.md`
- Deployment scripts: `flutter/packages/admin/*.sh`
