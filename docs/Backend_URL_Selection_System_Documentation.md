# Backend URL Selection System Documentation

## Overview

This document describes how GrowERP's Flutter frontend selects and manages backend URLs, including the dynamic backend URL discovery system that allows applications to connect to different backend servers based on configuration.

## System Architecture

The backend URL selection system operates through multiple components:

1. **Frontend URL Resolution** - Flutter function that determines appropriate backend URL
2. **Backend URL Discovery Service** - REST endpoint that provides backend URL configuration
3. **Database Storage** - Entity-based storage of backend URL mappings
4. **UI Management** - Flutter screens for managing backend URL configurations

## Frontend URL Resolution

### Main Execution Flow

The primary backend URL resolution logic is implemented in:
```
flutter/packages/growerp_core/lib/src/domains/common/functions/get_backend_url.dart
```

#### Function: `getBackendUrlOverride`

**Purpose**: Determines the appropriate backend URL based on environment (debug vs production) and application configuration.

**Parameters**:
- `classificationId` (String): Application identifier used to lookup backend URL
- `version` (String): Application version for backend compatibility checking

**Logic Flow**:

1. **Environment Detection**:
   ```dart
   if (kDebugMode) {
     // Debug/Development Environment
     bool android = Platform.isAndroid;
     backendBaseUrl = android ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
     databaseUrl = 'databaseUrlDebug';
     chatUrl = 'chatUrlDebug';
     secure = '';
   } else {
     // Production Environment
     backendBaseUrl = 'https://backend.growerp.com';
     databaseUrl = 'databaseUrl';
     chatUrl = 'chatUrl';
     secure = 's';
   }
   ```

2. **Backend URL Discovery Call**:
   ```dart
   backendUrl = '$backendBaseUrl/rest/s1/growerp/100/BackendUrl?version=$version&applicationId=$classificationId';
   response = await http.get(Uri.parse(backendUrl));
   ```

3. **Configuration Update**:
   ```dart
   String? appBackendUrl = jsonDecode(response.body)['backendUrl'];
   if (response.statusCode == 200 && appBackendUrl != null) {
     GlobalConfiguration().updateValue(databaseUrl, "http$secure://$appBackendUrl");
     GlobalConfiguration().updateValue(chatUrl, "ws$secure://$appBackendUrl");
     GlobalConfiguration().updateValue("test", true);
   }
   ```

### Environment-Specific Behavior

- **Debug Mode (Development)**:
  - Android Emulator: Uses `10.0.2.2:8080` (Android emulator host mapping)
  - Other Platforms: Uses `localhost:8080`
  - Unencrypted HTTP connections

- **Production Mode**:
  - Uses `backend.growerp.com` as discovery endpoint
  - HTTPS/WSS encrypted connections
  - Dynamic backend URL resolution

## Backend URL Discovery Service

### REST Endpoint

**URL**: `/rest/s1/growerp/100/BackendUrl`

**Method**: GET

**Parameters**:
- `version`: Application version string
- `applicationId`: Classification ID for the application

**Service Name**: `growerp.100.GeneralServices100.get#BackendUrl`

### Response Format

```json
{
  "backendUrl": "target-backend-hostname:port"
}
```

### Service Implementation

The backend service performs the following operations:

1. **Application Lookup**: Uses `applicationId` (classificationId) to find the corresponding backend URL configuration
2. **Version Validation**: Checks if the requested version is compatible with the backend
3. **URL Resolution**: Returns the appropriate backend hostname/port for the application
4. **Multi-tenancy Support**: Supports different backend URLs for different applications/tenants

## Database Storage

### Entity: `mantle.party.PartyClassification`

Backend URLs are stored in the Moqui database using the `mantle.party.PartyClassification` entity, which provides a flexible classification system for applications and their backend configurations.

#### Entity Structure

The `PartyClassification` entity links applications to their backend configurations:

```xml
<entity entity-name="PartyClassification" package="mantle.party" cache="true">
  <field name="partyClassificationId" type="id" is-pk="true"/>
  <field name="classificationTypeEnumId" type="id"/>
  <field name="parentClassificationId" type="id"/>
  <field name="description" type="text-medium"/>
  <field name="standardCode" type="text-medium"/>
</entity>
```

#### Backend URL Storage Pattern

The `standardCode` field serves as the key connection between applications and their backend configurations:

- **partyClassificationId**: Unique identifier for the classification (matches the application's classificationId)
- **classificationTypeEnumId**: Type of classification (can be used to categorize different types of backend mappings)
- **parentClassificationId**: Supports hierarchical classifications for organization
- **description**: Human-readable description of the application or configuration
- **standardCode**: **Critical field** - stores the backend base URL and minimum app version information for determining whether to use test backend vs production backend

### Data Relationships

The backend URL selection system uses the following data flow:

```
Application (classificationId)
    ↓
PartyClassification.partyClassificationId (matches classificationId)
    ↓
PartyClassification.standardCode (contains backend URL and version logic)
    ↓
Backend URL Resolution (test vs production backend selection)
```

#### How standardCode Works

The `standardCode` field contains the logic for backend URL selection and version-based environment routing:

1. **Backend Base URL**: The primary backend server hostname/port
2. **Minimum App Version**: Version threshold for determining test vs production backend
3. **Environment Logic**: Rules for when to route to test backend instead of production

**Example standardCode patterns**:
- Simple backend URL: `"backend.growerp.com:8080"`
- Version-based routing: `"backend.growerp.com:8080|minVersion:1.5.0|testBackend:test.growerp.com:8080"`
- Environment-specific: `"prod:backend.growerp.com|test:test.growerp.com|minProdVersion:2.0.0"`

The backend service `growerp.100.GeneralServices100.get#BackendUrl` parses the `standardCode` field to determine:
- Which backend URL to return based on the requesting application version
- Whether the application should use the test backend or production backend
- Version compatibility and routing rules

## UI Management

### ApplicationList Screen

**Location**: Determined from search results - multiple application list implementations exist

**Purpose**: Provides administrative interface for managing application configurations including backend URLs

#### Key Features

1. **Application Display**: Shows list of configured applications with their backend URLs
2. **Edit Functionality**: Allows modification of backend URL assignments
3. **Table View**: Displays applications in tabular format with backend URL column
4. **Administrative Access**: Restricted to admin users for security

#### Screen Components

- **ApplicationList Widget**: Main list/table display
- **ApplicationDialog**: Edit dialog for individual applications
- **ApplicationBloc**: State management for application operations
- **Table Configuration**: Defined in application_list_table_def.dart

### ApplicationDialog

**Location**: `flutter/packages/support/lib/src/application/views/application_dialog.dart`

**Purpose**: Provides form-based interface for editing application backend URL configurations

#### Form Fields

```dart
class ApplicationDialog extends StatefulWidget {
  // Form Controllers
  final _idController = TextEditingController();           // Application ID
  final _versionController = TextEditingController();      // Version
  final _backendUrlController = TextEditingController();   // Backend URL
}
```

#### Form Validation

```dart
TextFormField(
  key: const Key('backendUrl'),
  decoration: const InputDecoration(labelText: 'Backend URL'),
  controller: _backendUrlController,
  validator: (value) {
    if (value!.isEmpty) {
      return 'Please enter a backend URL?';
    }
    return null;
  },
)
```

#### Update Operation

```dart
_applicationBloc.add(ApplicationUpdate(Application(
  applicationId: _idController.text,
  version: _versionController.text,
  backendUrl: _backendUrlController.text
)));
```

## Configuration Flow

### Complete Backend URL Selection Process

1. **Application Startup**:
   - Application determines its `classificationId` and `version`
   - Calls `getBackendUrlOverride(classificationId, version)`

2. **Environment Check**:
   - Debug mode: Uses local/development backend URLs
   - Production mode: Proceeds to backend URL discovery

3. **Backend URL Discovery**:
   - Makes HTTP GET request to `/rest/s1/growerp/100/BackendUrl`
   - Passes `applicationId` (classificationId) and `version` parameters

4. **Backend Service Processing**:
   - Looks up `PartyClassification` record where `partyClassificationId = applicationId`
   - Parses the `standardCode` field to extract backend URL and version rules
   - Compares the requesting application version against minimum version thresholds
   - Determines whether to return test backend URL or production backend URL
   - Returns appropriate backend URL based on version compatibility and environment rules

5. **Frontend Configuration Update**:
   - Updates `GlobalConfiguration` with received backend URL
   - Sets database URL: `http(s)://backend-url`
   - Sets chat URL: `ws(s)://backend-url`
   - Marks configuration as active

6. **Application Operation**:
   - All subsequent REST calls use the resolved backend URL
   - WebSocket connections use the resolved chat URL

### Administrative Configuration

1. **Backend URL Management**:
   - Administrators access ApplicationList screen
   - View existing application-to-backend URL mappings
   - Edit configurations via ApplicationDialog

2. **Database Updates**:
   - Changes to backend URL mappings are stored by updating the `standardCode` field in `PartyClassification` entities
   - New backend URLs and version rules are immediately available for discovery
   - No date-based versioning - direct field updates for immediate effect

3. **Multi-tenant Support**:
   - Different applications can have different backend URLs
   - Supports development, staging, and production environments
   - Enables backend server load distribution

## Security Considerations

### Access Control

- **ApplicationList Screen**: Admin-only access
- **Backend URL Discovery**: Public endpoint (requires valid applicationId)
- **Database Storage**: Protected by Moqui entity-level security

### Validation

- **URL Format**: Frontend validates backend URL format
- **Version Compatibility**: Backend service validates version compatibility
- **Classification Verification**: Backend verifies valid application classifications

## Error Handling

### Frontend Error Handling

```dart
try {
  response = await http.get(Uri.parse(backendUrl));
  // Process response
} catch (error) {
  debugPrint('===get backend url: $backendUrl error: $error');
}
```

### Fallback Behavior

- **Network Errors**: Falls back to default backend configuration
- **Invalid Classifications**: Uses base backend URL
- **Service Unavailable**: Continues with existing configuration

## Development and Testing

### Local Development

- **Debug Mode**: Automatically uses localhost/emulator URLs
- **No Discovery**: Bypasses backend URL discovery service
- **Direct Connection**: Connects directly to local Moqui instance

### Production Deployment

- **Discovery Required**: Must use backend URL discovery service
- **Database Configuration**: Backend URLs must be configured in database
- **HTTPS Required**: All production connections use encrypted protocols

## Integration Points

### Global Configuration

The system integrates with GrowERP's global configuration system:

```dart
GlobalConfiguration().updateValue(databaseUrl, "http$secure://$appBackendUrl");
GlobalConfiguration().updateValue(chatUrl, "ws$secure://$appBackendUrl");
```

### REST Client

All REST API calls use the resolved backend URL from global configuration.

### WebSocket Chat

Chat connections use the resolved WebSocket URL for real-time communication.

## Extensibility

### Adding New Applications

1. Create new `PartyClassification` record with:
   - `partyClassificationId`: Set to the application's classification ID
   - `description`: Human-readable application name/description
   - `standardCode`: Backend URL and version rules (e.g., `"backend.growerp.com:8080|minVersion:1.0.0"`)
2. Use the classification ID in the new Flutter application
3. Backend URL discovery automatically works based on the `standardCode` parsing

### Backend Server Scaling

1. Deploy new backend servers
2. Update `PartyClassification.standardCode` fields with new URL patterns
3. Applications automatically discover new backend URLs on next startup
4. Supports version-based routing for gradual migration between backends
5. Enables load balancing and geographic distribution through URL routing rules

This system provides a flexible, scalable foundation for GrowERP's multi-tenant, multi-backend architecture while maintaining simplicity for development environments. The `standardCode` field in `PartyClassification` serves as the central configuration point for backend URL routing, enabling version-based environment selection and sophisticated backend server management without requiring complex date-based versioning or party associations.
