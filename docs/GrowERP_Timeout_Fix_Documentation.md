# GrowERP Timeout Configuration Fix

## Problem

When initially logging into GrowERP and requesting demo data on cloud servers, users experience request timeouts. This happens because demo data creation involves extensive database operations that can take several minutes to complete, especially on cloud infrastructure with network latency and resource constraints.

## Root Cause Analysis

1. **Demo Data Creation is Heavy**: The login endpoint (`rest/s1/growerp/100/Login`) with `demoData: true` creates comprehensive sample data including:
   - Companies and users
   - Products and categories  
   - Orders and invoices
   - Accounting entries
   - Inventory records
   - Marketing data
   - And many other related entities

2. **Previous Timeout Values Were Too Low**:
   - Production: 10 seconds connect, 10 seconds receive
   - Test: 20 seconds connect, 40 seconds receive
   - These values were insufficient for demo data creation on cloud servers

3. **Configuration Not Used**: The timeout values in `app_settings.json` were not being used by the `buildDioClient` function, which had hardcoded values.

## Solution Implementation

### 1. Fixed buildDioClient to Use Configuration Timeouts

**File**: `flutter/packages/growerp_core/lib/src/services/build_dio_client.dart`

- Modified `buildDioClient` to read timeout values from `GlobalConfiguration`
- Implemented logic to use longer of provided timeout vs configuration timeout
- Added proper fallback values

```dart
// Get timeout values from configuration
int connectTimeoutSeconds;
int receiveTimeoutSeconds;

if (kReleaseMode) {
  connectTimeoutSeconds = GlobalConfiguration().get('connectTimeoutProd') ?? 15;
  receiveTimeoutSeconds = GlobalConfiguration().get('receiveTimeoutProd') ?? 60;
} else {
  connectTimeoutSeconds = GlobalConfiguration().get('connectTimeoutTest') ?? 20;
  receiveTimeoutSeconds = GlobalConfiguration().get('receiveTimeoutTest') ?? 120;
}

// Use provided timeout duration if it's longer than config, otherwise use config
final configReceiveTimeout = Duration(seconds: receiveTimeoutSeconds);
final effectiveReceiveTimeout = timeout.inSeconds > configReceiveTimeout.inSeconds 
    ? timeout 
    : configReceiveTimeout;
```

### 2. Increased Timeout Values in Configuration

**Updated Values**:
- `connectTimeoutProd`: 10 → 30 seconds
- `receiveTimeoutProd`: 10 → 300 seconds (5 minutes)
- `connectTimeoutTest`: 20 → 30 seconds  
- `receiveTimeoutTest`: 40 → 600 seconds (10 minutes)

### 3. Added Special Handling for Demo Data Login

**File**: `flutter/packages/growerp_core/lib/src/domains/authenticate/blocs/auth_bloc.dart`

- Added logic to use extended timeout (15 minutes) specifically for demo data creation
- Creates a separate RestClient instance with extended timeout when `demoData: true`

```dart
// Use extended timeout for demo data creation as it involves heavy database operations
final clientToUse = event.demoData == true 
    ? RestClient(await buildDioClient(timeout: const Duration(seconds: 900))) // 15 minutes for demo data
    : restClient;
```

### 4. Updated All App Configuration Files

Updated timeout values in all `app_settings.json` files across:
- Main applications: admin, hotel, freelance, health, support
- Example packages and test configurations
- Build artifacts

## Files Modified

### Core Changes
- `flutter/packages/growerp_core/lib/src/services/build_dio_client.dart` - Fixed to use config timeouts
- `flutter/packages/growerp_core/lib/src/domains/authenticate/blocs/auth_bloc.dart` - Added demo data special handling

### Configuration Updates
- `flutter/packages/admin/assets/cfg/app_settings.json`
- `flutter/packages/hotel/assets/cfg/app_settings.json`
- `flutter/packages/freelance/assets/cfg/app_settings.json`
- `flutter/packages/health/assets/cfg/app_settings.json`
- `flutter/packages/support/assets/cfg/app_settings.json`
- All example and build configuration files

### Utility Script
- `flutter/update_timeouts.sh` - Script to update timeout values across all config files

## Testing Recommendations

1. **Test Demo Data Creation**: 
   - Try creating a new company with demo data on cloud server
   - Verify the process completes without timeout errors
   - Monitor the actual time taken (should be under 10 minutes typically)

2. **Test Regular Operations**:
   - Ensure normal API calls still work with updated timeouts
   - Verify no performance regression in regular operations

3. **Test Different Environments**:
   - Local development (should use test timeouts)
   - Production deployment (should use production timeouts)

## Monitoring

Consider adding logging to track:
- Actual time taken for demo data creation
- Timeout occurrences and patterns
- Performance differences between environments

## Future Improvements

1. **Progressive Demo Data Creation**: Split demo data creation into smaller chunks with progress indicators
2. **Background Processing**: Move demo data creation to a background job with status updates
3. **Configurable Demo Data**: Allow users to select which demo data categories to include
4. **Timeout Metrics**: Collect metrics on actual operation times to optimize timeout values

## Rollback Plan

If issues arise, timeout values can be quickly reverted by:
1. Running the update script with previous values
2. Reverting the buildDioClient changes
3. Removing the special demo data handling in auth_bloc

The changes are backward compatible and don't affect the core functionality.