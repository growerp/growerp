# Service Worker Caching Architecture

## Overview
The Flutter Admin app uses a Service Worker to cache assets for offline support and faster loading on repeat visits.

## Architecture

### How It Works
```
1. User visits http://localhost:8080/admin/
   ↓
2. Moqui serves admin/index.html
   ↓
3. index.html registers flutter_service_worker.js
   ↓
4. Service Worker installs and caches CORE files:
   - main.dart.js (the Flutter app)
   - index.html
   - flutter_bootstrap.js
   - assets/AssetManifest.bin.json
   - assets/FontManifest.json
   ↓
5. Flutter bootstrap loads main.dart.js
   ↓
6. App initializes and runs
   ↓
7. Service Worker caches additional resources as they're fetched
   ↓
8. User closes browser
   ↓
9. User returns to http://localhost:8080/admin/
   ↓
10. Service Worker serves main.dart.js from CACHE! ⚡
```

### File Locations
```
/admin/
├── index.html                      ← Registers service worker
├── flutter_service_worker.js       ← Service worker script
├── main.dart.js                    ← Flutter app (cached)
├── flutter_bootstrap.js            ← Bootstrap loader
└── assets/                         ← App assets (cached)
```

### Service Worker Registration
**Location:** `/admin/index.html`

```javascript
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('flutter_service_worker.js', {
        scope: './'
      }).then(registration => {
        console.log('✅ Flutter Admin Service Worker registered');
      });
    });
  }
</script>
```

**Key Points:**
- Registration happens in `index.html` (NOT in root.html.ftl)
- Scope is `./` which equals `/admin/`
- Registration happens on window load (before Flutter bootstrap)

## Caching Strategy

### Install Phase
When the service worker installs:
```javascript
const CORE = [
  "main.dart.js",        // ← THIS IS CACHED!
  "index.html",
  "flutter_bootstrap.js",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json"
];
```

### Fetch Phase
When the app requests resources:
```javascript
event.respondWith(
  cache.match(request).then(response => {
    // Return cached version if available
    return response || fetch(request).then(response => {
      // Cache new resources
      cache.put(request, response.clone());
      return response;
    });
  })
);
```

## Testing Caching

### Step 1: Clear Cache
1. Open DevTools (F12)
2. Application → Storage → Clear site data
3. Application → Service Workers → Unregister all

### Step 2: First Visit
1. Visit `http://localhost:8080/admin/`
2. Open Network tab (keep DevTools open)
3. Look for `main.dart.js` - should show:
   - **Status:** 200
   - **Size:** ~7.9 MB (actual size)
   - **Initiator:** flutter_service_worker.js

4. Check Console - should see:
   ```
   ✅ Flutter Admin Service Worker registered with scope: http://localhost:8080/admin/
   ```

5. Check Application → Service Workers:
   - Status: **activated and is running**
   - Scope: `http://localhost:8080/admin/`

### Step 3: Second Visit (CACHE TEST)
1. Close browser tab
2. Reopen `http://localhost:8080/admin/`
3. Open Network tab
4. Look for `main.dart.js` - should show:
   - **Status:** 200
   - **Size:** `(disk cache)` or `(ServiceWorker)` ← THIS IS THE GOAL!
   - **Time:** < 10ms (vs 200+ ms on first load)

### Step 4: Offline Test
1. DevTools → Network → Toggle "Offline"
2. Reload page
3. App should still load! 🎉

## Expected Console Output

### First Load
```
✅ Flutter Admin Service Worker registered with scope: http://localhost:8080/admin/
[Service Worker] Installing service worker...
[Service Worker] Caching core files...
[Service Worker] Installation complete
```

### Second Load
```
✅ Flutter Admin Service Worker registered with scope: http://localhost:8080/admin/
[Service Worker] Serving main.dart.js from cache
[Service Worker] Serving assets from cache
```

## Troubleshooting

### main.dart.js Not Cached
**Problem:** Network tab shows main.dart.js loading from network on repeat visits

**Causes:**
1. Service worker not activated
   - Check: DevTools → Application → Service Workers
   - Fix: Wait for "activated and is running" status

2. Service worker scope mismatch
   - Check: Console for scope errors
   - Fix: Ensure scope is `./` in registration

3. Cache invalidated
   - Cause: Hard refresh (Ctrl+Shift+R)
   - Fix: Use normal refresh (F5) to test caching

4. Service worker updated
   - Cause: flutter_service_worker.js changed (new build)
   - Expected: Old cache cleared, new cache installed

### "prepareServiceWorker timeout" Error
**Problem:** Flutter bootstrap times out waiting for service worker

**Cause:** Service worker registration happens too late

**Fix:** Already implemented - registration is in `index.html` before `flutter_bootstrap.js`

### 404 on flutter_service_worker.js
**Problem:** Service worker script not found

**Check:**
```bash
ls -la /home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin/flutter_service_worker.js
```

**Fix:** Run deployment script:
```bash
cd /home/hans/growerp/flutter/packages/admin
./deploy-web-to-moqui.sh
```

## Cache Lifecycle

### Update Flow
```
1. Developer builds new Flutter version
   ↓
2. flutter_service_worker.js gets new hash values
   ↓
3. User visits /admin/
   ↓
4. Browser detects new service worker version
   ↓
5. New service worker installs in background
   ↓
6. User closes all tabs
   ↓
7. New service worker activates
   ↓
8. Old cache deleted
   ↓
9. New cache populated
   ↓
10. User's next visit uses new cache
```

### Manual Cache Clear
```javascript
// In browser console:
navigator.serviceWorker.getRegistrations().then(registrations => {
  registrations.forEach(reg => reg.unregister());
});
caches.keys().then(keys => {
  keys.forEach(key => caches.delete(key));
});
```

## Performance Metrics

### First Load (No Cache)
- main.dart.js: ~200-500ms
- Total load time: ~1-2 seconds
- Data transferred: ~8 MB

### Second Load (With Cache)
- main.dart.js: ~5-10ms ⚡
- Total load time: ~200-500ms ⚡
- Data transferred: ~0 KB ⚡

### Offline Load
- Works! ✅
- Load time: ~200-500ms
- Data: from cache

## Best Practices

1. **Always register service worker in index.html**
   - Before flutter_bootstrap.js
   - On window load event

2. **Use relative paths in registration**
   - `flutter_service_worker.js` (relative)
   - NOT `/admin/flutter_service_worker.js` (absolute)

3. **Set correct scope**
   - `./` for same directory
   - Matches base href

4. **Test caching after every deployment**
   - Clear cache
   - First load (should cache)
   - Second load (should use cache)

5. **Monitor console for errors**
   - Service worker registration
   - Cache operations
   - Fetch events

## References
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Flutter Web Service Workers](https://docs.flutter.dev/platform-integration/web/service-workers)
- [Cache API](https://developer.mozilla.org/en-US/docs/Web/API/Cache)
