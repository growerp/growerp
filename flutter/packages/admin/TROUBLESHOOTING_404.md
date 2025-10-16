# Troubleshooting: Page Not Found (404) for /admin/

## The Problem

When clicking the "Admin" link, you see:
```
Page Not Found (404)
Could not find admin under Webroot.
The full path was: admin
```

## Root Cause

Moqui needs to be restarted after adding new screen files (admin.xml) so it can discover and register the new subscreen.

## Solution

### Step 1: Verify Files Are In Place

Check that these files exist:

```bash
# The screen definition
ls -la /home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin.xml

# The Flutter app files
ls -la /home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin/

# Should show:
# - index.html
# - flutter_service_worker.js
# - main.dart.js
# - flutter.js
# - assets/
# - canvaskit/
# - etc.
```

### Step 2: Restart Moqui Server

**If running Moqui:**

1. Stop the Moqui server (Ctrl+C if running in foreground)
2. Restart it:
   ```bash
   cd /home/hans/growerp/moqui
   java -jar moqui.war
   ```

3. Wait for Moqui to fully start (watch for "Startup complete")

### Step 3: Test Access

After restart, try these URLs:

1. **Main store**: `http://localhost:8080/`
2. **Admin link**: Click "Admin" in navbar
3. **Direct access**: `http://localhost:8080/admin/`
4. **Test page**: `http://localhost:8080/admin/service-worker-test.html`

### Step 4: Check Browser Console

Open browser DevTools (F12) and check:

1. **Console tab**: Look for errors
2. **Network tab**: Check if files are loading (should see flutter.js, main.dart.js, etc.)
3. **Application → Service Workers**: Check if service worker registered

## Why Restart Is Needed

Moqui discovers subscreens at startup by:

1. Scanning `screen/store/` directory
2. Finding all `.xml` files
3. Registering them as subscreens
4. Building the URL routing table

When you add a new screen file (`admin.xml`) after Moqui is running, it doesn't automatically detect it. You must restart for the new screen to be discovered.

## Alternative: Hot Reload (If Supported)

Some Moqui configurations support hot reload, but this depends on your setup. Restart is the reliable method.

## Verification Checklist

After restart, verify:

- [ ] Moqui started without errors
- [ ] Can access main store at `/`
- [ ] Can click "Admin" link in navbar
- [ ] Admin app loads at `/admin/`
- [ ] No 404 errors in browser console
- [ ] Service worker registers (check DevTools)
- [ ] Flutter app displays correctly

## Still Not Working?

### Check Log Files

```bash
tail -f /home/hans/growerp/moqui/runtime/log/moqui.log
```

Look for errors related to:
- Screen initialization
- File not found
- Permission errors

### Verify File Permissions

```bash
# Make sure files are readable
chmod -R 755 /home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin/
chmod 644 /home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin.xml
```

### Check Moqui Configuration

Verify in `/home/hans/growerp/moqui/runtime/component/PopRestStore/MoquiConf.xml`:

```xml
<screen location="component://webroot/screen/webroot.xml" default-subscreen="m">
    <subscreens-item name="m" menu-title="GrowERP Ecommerce" menu-include="false"
            location="component://PopRestStore/screen/store.xml" no-sub-path="true"/>
</screen>
```

This configuration makes `store.xml` the root, and it has:
```xml
<subscreens default-item="home" always-use-full-path="true"/>
```

Which means `admin.xml` in the same directory should be auto-discovered.

### Test Direct File Access

Try accessing static files directly:

```
http://localhost:8080/admin/flutter.js
http://localhost:8080/admin/favicon.png
http://localhost:8080/components/combined.min.js (this should work as reference)
```

If these don't work, there might be a webroot configuration issue.

## Common Mistakes

1. **❌ Not restarting Moqui** - Most common cause!
2. **❌ Wrong file location** - Files must be in `screen/store/admin/` not elsewhere
3. **❌ Missing admin.xml** - The screen definition file is required
4. **❌ Incorrect base href** - Must be `/admin/` in index.html
5. **❌ Permission issues** - Files must be readable by Moqui process

## Success Indicators

When working correctly:

1. ✅ No 404 error on `/admin/`
2. ✅ Index.html loads
3. ✅ Flutter loading spinner appears
4. ✅ Network tab shows all assets loading
5. ✅ Service worker registers successfully
6. ✅ Flutter app fully renders

## Next Steps After Fix

Once admin is accessible:

1. Test the service worker (visit `/admin/service-worker-test.html`)
2. Try going offline (DevTools → Network → Offline)
3. Refresh - app should still work (after initial load)
4. Configure your Flutter app as needed

## Need More Help?

Check these files for reference:
- `flutter/packages/admin/DEPLOY_WEB.md` - Full deployment guide
- `flutter/packages/admin/SERVICE_WORKER_QUICK_REF.md` - Quick reference
- Moqui logs at `moqui/runtime/log/moqui.log`
