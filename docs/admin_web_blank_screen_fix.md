# Admin Web App Blank Screen Fix

## Problem
When clicking the "admin" link on the test deep links page (`test_deep_links.html`), the browser showed a blank screen with only XML comments:
```html
<!-- BEGIN screen[@location=component://PopRestStore/screen/store/admin.xml].widgets -->
<!-- BEGIN render-mode.text[@location=component://PopRestStore/screen/store/admin/index.html][@template=true] -->
<!-- END   render-mode.text[@location=component://PopRestStore/screen/store/admin/index.html][@template=true] -->
```

## Root Cause
The Flutter admin web application had not been built and deployed to the Moqui backend. The Moqui server (running on port 8080) was trying to serve the admin app at `/admin/`, but the `index.html` file and other Flutter web assets were missing from the expected location:
- Expected location: `/moqui/runtime/component/PopRestStore/screen/store/admin/`
- The directory didn't exist, so Moqui rendered an empty screen

## Solution

### 1. Built and Deployed the Admin Web App
Ran the build and deployment script:
```bash
cd /home/hans/growerp/flutter/packages/admin
./build-and-deploy-web.sh
```

This script:
- Builds the Flutter admin web app with WASM support
- Copies the build output to the Moqui runtime directory
- Fixes the base href to `/admin/`
- Removes duplicate service worker registration
- Creates the necessary Moqui screen XML file

### 2. Enhanced User Experience for Future Cases
Created a user-friendly setup notice that displays when the Flutter build hasn't been deployed:

#### Created Files:
1. **`/moqui/runtime/component/PopRestStore/screen/store/admin_setup_notice.html`**
   - Beautiful, styled HTML page with clear setup instructions
   - Shows when the Flutter build is missing
   - Provides step-by-step deployment instructions

2. **Updated `/moqui/runtime/component/PopRestStore/screen/store/admin.xml`**
   - Added conditional logic to check if `index.html` exists
   - If deployed: serves the Flutter admin app
   - If not deployed: shows the setup notice page
   - Uses Groovy script in `<actions>` section to check file existence

3. **Updated `/flutter/packages/admin/deploy-web-to-moqui.sh`**
   - Enhanced to automatically create the setup notice file
   - Creates the enhanced admin.xml with conditional rendering
   - Only applies to admin app (assessment app uses simple screen)

## Technical Details

### Conditional Rendering in admin.xml
```xml
<actions>
    <script><![CDATA[
        // Check if the Flutter admin build has been deployed
        def indexResource = ec.resource.getLocationReference("component://PopRestStore/screen/store/admin/index.html")
        context.adminDeployed = indexResource != null && indexResource.exists
    ]]></script>
</actions>

<widgets>
    <render-mode>
        <text type="html"><![CDATA[
            <#if adminDeployed!false>
                ${ec.resource.getLocationText("component://PopRestStore/screen/store/admin/index.html", false)}
            <#else>
                ${ec.resource.getLocationText("component://PopRestStore/screen/store/admin_setup_notice.html", false)}
            </#if>
        ]]></text>
    </render-mode>
</widgets>
```

### Benefits
1. **Better Developer Experience**: No more blank screens - developers see clear instructions
2. **Self-Documenting**: The setup notice explains what's needed and why
3. **Docker vs Local**: Clearly distinguishes between Docker (automatic) and local (manual) setup
4. **Idempotent**: The deployment script can be run multiple times safely

## Testing
After deployment, verified that:
- ✅ Admin app loads correctly at `http://localhost:8080/admin/`
- ✅ Flutter service worker is accessible
- ✅ Base href is correctly set to `/admin/`
- ✅ All assets (JS, WASM, icons, etc.) are deployed

## Future Improvements
If the Flutter build is removed or missing in the future, users will see the helpful setup notice instead of a blank screen, making it much easier to diagnose and fix the issue.

## Related Files
- `/home/hans/growerp/flutter/packages/admin/build-and-deploy-web.sh` - Main build and deploy script
- `/home/hans/growerp/flutter/packages/admin/deploy-web-to-moqui.sh` - Deployment-only script
- `/home/hans/growerp/flutter/packages/admin/DEPLOY_WEB.md` - Deployment documentation
- `/home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin.xml` - Moqui screen definition
- `/home/hans/growerp/moqui/runtime/component/PopRestStore/screen/store/admin_setup_notice.html` - Setup notice page
