# Backend URL Configuration Fix for Local Development

## Problem
The admin web app was using `https://backend.growerp.org` (production backend) even when running locally at `http://localhost:8080/admin/`. This caused the app to fail to connect to the local Moqui backend.

## Root Cause
The Flutter web build is compiled in **release mode** by default, which uses the `databaseUrl` setting from `app_settings.json`:
```json
{
  "databaseUrl": "https://backend.growerp.com",
  "chatUrl": "wss://backend.growerp.com"
}
```

The logic in `build_dio_client.dart` is:
- **Release mode**: Uses `databaseUrl` (production)
- **Debug mode with `databaseUrlDebug` set**: Uses `databaseUrlDebug`
- **Debug mode without `databaseUrlDebug`**: Uses `http://localhost:8080` (or `http://10.0.2.2:8080` for Android)

Since the web build is in release mode, it always used the production URL.

## Solution
Modified the deployment script (`deploy-web-to-moqui.sh`) to automatically update the `app_settings.json` in the deployed build to use **relative URLs**:

### Changes Made
1. **Updated `deploy-web-to-moqui.sh`** to modify `app_settings.json` after copying files:
   ```bash
   # Update app_settings.json to use relative URLs for backend when deployed to Moqui
   APP_SETTINGS_FILE="$MOQUI_TARGET_DIR/assets/assets/cfg/app_settings.json"
   sed -i 's|"databaseUrl": *"https://backend\.growerp\.com"|"databaseUrl": "/rest"|g' "$APP_SETTINGS_FILE"
   sed -i 's|"chatUrl": *"wss://backend\.growerp\.com"|"chatUrl": "ws://localhost:8080/chat"|g' "$APP_SETTINGS_FILE"
   ```

2. **Result**: The deployed `app_settings.json` now contains:
   ```json
   {
     "databaseUrl": "/rest",
     "chatUrl": "ws://localhost:8080/chat"
   }
   ```

### How It Works
- **Relative URL `/rest`**: When the browser loads the admin app from `http://localhost:8080/admin/`, the relative URL `/rest` resolves to `http://localhost:8080/rest`
- **Same origin**: This ensures the app uses the same backend server it's served from
- **Works everywhere**: 
  - Local development: `http://localhost:8080/rest`
  - Production: `https://yourdomain.com/rest`
  - Docker: Works with any host configuration

## Benefits
1. ✅ **Automatic**: No manual configuration needed
2. ✅ **Portable**: Works on localhost, Docker, and production
3. ✅ **Consistent**: Same deployment process for all environments
4. ✅ **Simple**: Uses standard relative URL resolution

## Testing
After redeployment:
```bash
cd /home/hans/growerp/flutter/packages/admin
./deploy-web-to-moqui.sh admin
```

Verify the configuration:
```bash
curl http://localhost:8080/admin/assets/assets/cfg/app_settings.json | grep databaseUrl
# Should show: "databaseUrl": "/rest",
```

## Alternative Approaches Considered
1. **Use `databaseUrlDebug`**: Would require maintaining two separate configurations
2. **Build in debug mode**: Would include debug symbols and be much larger
3. **Environment variables**: Not available in Flutter web release builds
4. **Runtime detection**: Would add complexity and potential bugs

The relative URL approach is the cleanest and most maintainable solution.

## Related Files
- `/home/hans/growerp/flutter/packages/admin/deploy-web-to-moqui.sh` - Deployment script with URL fix
- `/home/hans/growerp/flutter/packages/admin/assets/cfg/app_settings.json` - Source configuration (unchanged)
- `/home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin/assets/assets/cfg/app_settings.json` - Deployed configuration (modified)
- `/home/hans/growerp/flutter/packages/growerp_core/lib/src/services/build_dio_client.dart` - Backend URL resolution logic

## Future Improvements
Consider using the same approach for the assessment app and any other web apps deployed to Moqui.
