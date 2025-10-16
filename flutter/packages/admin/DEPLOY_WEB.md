# Flutter Admin Web Deployment to Moqui

## Overview

The Flutter Admin web application can be deployed to the Moqui backend to be served alongside the PopRestStore component. This allows the service worker and all Flutter web assets to be accessible at the `/admin/` path.

## Directory Structure

```
moqui/runtime/component/PopRestStore/screen/store/
├── admin.xml                        # Moqui screen that serves the Flutter app entry point
└── admin/
    ├── flutter_service_worker.js    # Service worker for offline support
    ├── index.html                   # Main HTML entry point (served by admin.xml)
    ├── main.dart.js                 # Compiled Flutter/Dart code
    ├── flutter.js                   # Flutter engine loader
    ├── flutter_bootstrap.js         # Bootstrap script
    ├── manifest.json                # PWA manifest
    ├── favicon.png                  # Application icon
    ├── version.json                 # Build version info
    ├── service-worker-test.html     # Testing page
    ├── assets/                      # Flutter assets (fonts, images, etc.)
    ├── canvaskit/                   # CanvasKit WASM files
    └── icons/                       # PWA icons
```

**How Moqui Serves These Files:**
- `/admin/` → Handled by `admin.xml` screen, serves `admin/index.html`
- `/admin/flutter.js` → Served directly as static file from `admin/flutter.js`
- `/admin/assets/...` → Served directly as static files from `admin/assets/...`

## Deployment Scripts

### Option 1: Build and Deploy (Recommended)

```bash
cd flutter/packages/admin
./build-and-deploy-web.sh
```

This script will:
1. Clean previous builds
2. Get Flutter dependencies
3. Build the web application in release mode
4. Deploy the build to Moqui

### Option 2: Deploy Only

If you already have a build and just want to deploy:

```bash
cd flutter/packages/admin
./deploy-web-to-moqui.sh
```

### Option 3: Manual Deployment

```bash
# From project root
cp -r flutter/packages/admin/build/web/* \
      moqui/runtime/component/PopRestStore/screen/store/admin/
```

## Accessing the Application

After deployment, the Flutter admin application will be available at:

- **Main App**: `http://your-domain/admin/` or `http://your-domain/admin/index.html`
- **Service Worker**: `http://your-domain/admin/flutter_service_worker.js`
- **Test Page**: `http://your-domain/admin/service-worker-test.html`

### Navigation

You can access the admin app from the PopRestStore navbar:
- Look for the "Admin" link in the navigation bar (shows as a gear icon with "Admin" text)
- Click to navigate to `/admin/`

## Service Worker Registration

The service worker is registered **once in root.html.ftl** for optimal performance:

### Single Early Registration (PopRestStore root.html.ftl)

```javascript
// In root.html.ftl - registers early when main store loads
navigator.serviceWorker.register('/admin/flutter_service_worker.js', {
  scope: '/admin/'
})
```

**Benefits:**
- Service worker starts registering as soon as user visits the main store
- Ready immediately when user clicks "Admin" link
- Faster admin app startup - no registration delay
- Better user experience - instant load
- No duplicate registrations - avoids timeout issues

**Why not in admin/index.html?**
- Early registration in root.html.ftl is faster
- Flutter's bootstrap script finds the already-registered service worker
- Duplicate registration can cause timeouts ("prepareServiceWorker took more than 4000ms")
- Single registration point is cleaner and more maintainable

**Key Points:**
- Service worker scope is limited to `/admin/` path
- Service worker file must be at `/admin/flutter_service_worker.js`
- Base href is set to `/admin/` in index.html for proper asset loading
- Flutter bootstrap automatically uses the pre-registered service worker

This enables:
- Offline functionality
- Faster loading after first visit
- Background sync capabilities
- Push notifications support

## Development Workflow

### For Web Development:

1. **Make changes** in `flutter/packages/admin/`
2. **Test locally**:
   ```bash
   cd flutter/packages/admin
   flutter run -d chrome
   ```
3. **Build and deploy**:
   ```bash
   ./build-and-deploy-web.sh
   ```
4. **Restart Moqui** (if needed):
   ```bash
   cd moqui
   java -jar moqui.war
   ```

### Automated Deployment

The deployment script automatically:
1. Copies all Flutter web build files
2. **Fixes the base href** in index.html from `/` to `/admin/`
3. **Adds service worker registration** if not present
4. Verifies critical files were deployed

You can add the deployment script to your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
- name: Build Flutter Web
  run: |
    cd flutter/packages/admin
    flutter build web --release

- name: Deploy to Moqui
  run: |
    cd flutter/packages/admin
    ./deploy-web-to-moqui.sh
```

## Troubleshooting

### Testing Service Worker

Visit the test page to verify service worker registration:
```
http://your-domain/admin/service-worker-test.html
```

This page allows you to:
- Check browser support for service workers
- Register/unregister service workers
- View current registration status
- Navigate to the admin app

### Service Worker Not Found (404)

**Problem**: Browser console shows 404 for `/admin/flutter_service_worker.js`

**Solution**:
1. Verify files are deployed: `ls moqui/runtime/component/PopRestStore/screen/store/admin/`
2. Run deployment script: `./deploy-web-to-moqui.sh`
3. Restart Moqui server

### Old Version Cached

**Problem**: Changes not appearing after deployment

**Solution**:
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+Shift+R)
3. Check the `version.json` file to verify deployment

### Assets Not Loading

**Problem**: Images, fonts, or other assets returning 404

**Solution**:
1. Ensure the `assets/` directory was copied
2. Check file permissions: `chmod -R 755 moqui/runtime/component/PopRestStore/screen/store/admin/`
3. Verify in browser DevTools Network tab

## Notes

- The deployment scripts are idempotent - safe to run multiple times
- The admin directory is gitignored to avoid committing build artifacts
- Service worker caching means you may need to clear cache during development
- For production, consider using a CDN for static assets

## Related Files

- `flutter/packages/admin/build-and-deploy-web.sh` - Build and deploy script
- `flutter/packages/admin/deploy-web-to-moqui.sh` - Deployment-only script
- `moqui/runtime/component/PopRestStore/template/store/root.html.ftl` - Service worker registration
- `moqui/runtime/component/PopRestStore/screen/store/admin/` - Deployment target directory
