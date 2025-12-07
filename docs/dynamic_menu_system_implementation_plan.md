# Dynamic Menu System Refactoring

## Overview

Replace the current hardcoded `MenuOption` and `TabItem` models with a unified, dynamic `MenuItem` model that supports hierarchical menu structures. This will enable:
- A single model (`MenuItem`) to replace both `MenuOption` and `TabItem`
- Nested menu items (tabs) within parent menu items
- Dynamic menu configuration per application via `MenuConfiguration`
- **User-customizable menu structures** with per-user menu overrides
- Backend storage and retrieval of menu configurations
- **Migration from Navigator 1.0 to GoRouter** for declarative routing

## User Review Required

> [!IMPORTANT]
> **Breaking Change**: This is a complete replacement of the menu system. `MenuOption` and `TabItem` will be deleted entirely. All apps (admin, freelance, health, hotel, support) must migrate to the new `MenuItem` and `MenuConfiguration` models.

> [!WARNING]
> **Architecture Change**: The current system uses `Widget` and `Icon` objects directly in menu definitions and Navigator 1.0 for routing. The new system will replace this with:
> - **Icons**: Stored as icon names (strings) in the database. The app will map icon names to `Icon` objects.
> - **Widgets**: Replaced with route paths. All content will be accessed via routing instead of direct widget references.
> - **GoRouter**: Migration from Navigator 1.0 to GoRouter for declarative, type-safe routing with deep linking support.
> - This makes the entire menu configuration fully serializable and storable in the backend.

> [!IMPORTANT]
> **End-User Experience**: The implementation must be **completely transparent** to end users. The UI/UX must remain **identical** - same menu layout, same navigation behavior, same visual appearance. Only the underlying architecture changes. Users should not notice any difference in how the application looks or behaves.

## Proposed Changes

### growerp_models Package

#### [NEW] [menu_item_model.dart](file:///home/hans/growerp/flutter/packages/growerp_models/lib/src/models/menu_item_model.dart)

Create a new `MenuItem` model that merges `MenuOption` and `TabItem`:

```dart
@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    String? menuItemId,
    String? key,
    String? image, // path to image file
    String? selectedImage, // path to selected image file
    required String title,
    String? route, // route path for navigation
    String? iconName, // icon identifier (e.g., 'home', 'settings', 'business')
    List<MenuItem>? children, // nested menu items (tabs)
    String? floatButtonRoute, // route for floating action button
    List<UserGroup>? userGroups, // access control
    int? sequenceNum, // display order
  }) = _MenuItem;
  
  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}
```

**Key features:**
- Fully serializable - all fields can be stored in the database
- `iconName`: String identifier for icons (e.g., 'home', 'settings', 'business'). App maintains a map of icon names to `Icon` objects
- `route`: All content accessed via routing instead of direct widget references
- `children`: Nested menu items for tabbed interfaces
- `sequenceNum`: Controls display order of menu items

---

#### [NEW] [menu_configuration_model.dart](file:///home/hans/growerp/flutter/packages/growerp_models/lib/src/models/menu_configuration_model.dart)

Create a `MenuConfiguration` model to define app-level menu structure:

```dart
@freezed
class MenuConfiguration with _$MenuConfiguration {
  const factory MenuConfiguration({
    String? menuConfigurationId,
    required String appId,
    required String name,
    String? description,
    String? userLoginId, // null = default app menu, non-null = user-specific override
    required List<MenuItem> menuItems,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) = _MenuConfiguration;
  
  factory MenuConfiguration.fromJson(Map<String, dynamic> json) => 
      _$MenuConfigurationFromJson(json);
}
```

**Key features:**
- `menuConfigurationId`: Unique identifier for this configuration
- `appId`: Identifies which app this configuration belongs to (e.g., "admin", "freelance")
- `userLoginId`: If null, this is the default app menu; if set, this is a user-specific override
- `menuItems`: Root-level menu items
- Metadata for tracking changes

---

#### [MODIFY] [models.dart](file:///home/hans/growerp/flutter/packages/growerp_models/lib/src/models/models.dart)

Add exports for new models:
```dart
export 'menu_item_model.dart';
export 'menu_configuration_model.dart';
```

---

### growerp_core Package

#### [NEW] Icon Registry

Create an icon name to Icon object mapping in `growerp_core`:

- **Location**: `lib/src/domains/common/functions/icon_registry.dart`
- **Purpose**: Map icon names from database to Flutter Icon objects
- **Example**:
  ```dart
  final Map<String, Icon> iconRegistry = {
    'home': Icon(Icons.home),
    'business': Icon(Icons.business),
    'school': Icon(Icons.school),
    'settings': Icon(Icons.settings),
    'task': Icon(Icons.task),
    'money': Icon(Icons.money),
    'send': Icon(Icons.send),
    'call_received': Icon(Icons.call_received),
    'location_pin': Icon(Icons.location_pin),
    'question_answer': Icon(Icons.question_answer),
    'web': Icon(Icons.web),
    'quiz': Icon(Icons.quiz),
    'subscriptions': Icon(Icons.subscriptions),
    'webhook': Icon(Icons.webhook),
    // ... more icons
  };
  
  Icon? getIconByName(String? iconName) {
    if (iconName == null) return null;
    return iconRegistry[iconName];
  }
  ```

---

#### [DELETE] [menu_option_model.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/models/menu_option_model.dart)

Delete the entire file - no longer needed.

---

#### [DELETE] [tab_item_model.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/models/tab_item_model.dart)

Delete the entire file - no longer needed.

---

#### [MODIFY] [models.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/models/models.dart)

Remove old exports, file will be empty (can be deleted if no other models added):
```dart
// Old exports removed - MenuOption and TabItem deleted
```

---

#### [MODIFY] [display_menu_option.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/templates/display_menu_option.dart)

Completely rewrite to use only `MenuItem` with routing:

1. Replace `List<MenuOption> menuList` with `List<MenuItem> menuItems`
2. Remove all direct widget references (`child`, `form`, `floatButtonForm`)
3. Use `MenuItem.route` for navigation to all content
4. Use `MenuItem.children` for nested tab items
5. Convert `MenuItem.iconName` to `Icon` objects using icon registry
6. Handle both `iconName` (for tabs) and `image`/`selectedImage` (for main menu items)
7. For tabs, navigate to `route` when tab is selected instead of displaying widget directly

---

#### [MODIFY] [top_app.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/widgets/top_app.dart)

Replace menu options with menu configuration (already covered in GoRouter section above).

---

### GoRouter Migration

#### [NEW] GoRouter Setup

Replace Navigator 1.0 with GoRouter in all apps:

- **Add dependency**: Add `go_router` to `pubspec.yaml` in each app
- **Features**:
  - Declarative route definitions
  - Type-safe navigation
  - Deep linking support
  - Nested navigation for tabs
  - Route guards for authentication

---

#### [MODIFY] [top_app.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/widgets/top_app.dart)

Replace Navigator 1.0 with GoRouter:

1. Remove `onGenerateRoute` parameter and `Route<dynamic> Function(RouteSettings) router`
2. Accept `GoRouter` instance instead
3. Use `MaterialApp.router` instead of `MaterialApp`
4. Replace `menuOptions` with `menuConfiguration`
5. Initialize icon registry on app startup

```dart
class TopApp extends StatelessWidget {
  TopApp({
    required this.router, // Now GoRouter instead of route generator
    required this.menuConfiguration,
    // ... other parameters
  });
  
  final GoRouter router;
  final MenuConfiguration Function(BuildContext) menuConfiguration;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      // ... other configuration
    );
  }
}
```

---

#### [MODIFY] [display_menu_option.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/templates/display_menu_option.dart)

Update to use GoRouter navigation:

1. Replace all `Navigator.pushNamed` with `context.go()` or `context.push()`
2. Replace all `Navigator.pushReplacementNamed` with `context.go()`
3. Use `MenuItem.route` for navigation
4. For tabs, use `context.go()` to navigate to child routes
5. Convert `MenuItem.iconName` to `Icon` objects using icon registry

**Navigation changes:**
```dart
// Old:
await Navigator.pushNamed(context, route, arguments: args);

// New:
context.go(route);
// or for pushing:
context.push(route);
```

---

#### [MODIFY] Navigation Rail and Drawer

Update navigation widgets to use GoRouter:

- [my_navigationrail_widget.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/templates/my_navigationrail_widget.dart)
- [my_drawer_widget.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/templates/my_drawer_widget.dart)

Replace `Navigator.pushNamed` with `context.go()`

---

#### [MODIFY] [home_form.dart](file:///home/hans/growerp/flutter/packages/growerp_core/lib/src/domains/common/views/home_form.dart)

Update to work with `MenuConfiguration`:

1. Replace `menuOptions` parameter with `menuConfiguration`
2. Extract `menuItems` from `MenuConfiguration`
3. Pass `List<MenuItem>` to `DisplayMenuOption`

---

### Backend (Moqui)

#### [NEW] Entity Definitions

Create entities in `/home/hans/growerp/moqui/runtime/component/growerp/entity/GrowerpMenuEntities.xml`:

```xml
<entity entity-name="MenuConfiguration" package-name="growerp.menu">
  <field name="menuConfigurationId" type="id" is-pk="true"/>
  <field name="appId" type="id"/>
  <field name="name" type="text-medium"/>
  <field name="description" type="text-long"/>
  <field name="userLoginId" type="id"/>
  <field name="createdDate" type="date-time"/>
  <field name="lastModifiedDate" type="date-time"/>
  <relationship type="one" related="moqui.security.UserAccount" short-alias="user">
    <key-map field-name="userLoginId"/>
  </relationship>
</entity>

<entity entity-name="MenuItem" package-name="growerp.menu">
  <field name="menuItemId" type="id" is-pk="true"/>
  <field name="menuConfigurationId" type="id"/>
  <field name="parentMenuItemId" type="id"/> <!-- null for root items -->
  <field name="sequenceNum" type="number-integer"/> <!-- display order -->
  <field name="itemKey" type="text-short"/>
  <field name="image" type="text-medium"/> <!-- path to image -->
  <field name="selectedImage" type="text-medium"/>
  <field name="title" type="text-medium"/>
  <field name="route" type="text-medium"/>
  <field name="iconName" type="text-short"/> <!-- icon identifier for tabs -->
  <field name="floatButtonRoute" type="text-medium"/>
  <field name="userGroupsJson" type="text-long"/> <!-- JSON array of allowed user groups -->
  <relationship type="one" related="MenuConfiguration" short-alias="config">
    <key-map field-name="menuConfigurationId"/>
  </relationship>
  <relationship type="one" title="Parent" related="MenuItem" short-alias="parent">
    <key-map field-name="parentMenuItemId" related="menuItemId"/>
  </relationship>
  <relationship type="many" title="Children" related="MenuItem" short-alias="children">
    <key-map field-name="menuItemId" related="parentMenuItemId"/>
  </relationship>
</entity>
```

---

#### [NEW] Entity Views

Create views in `/home/hans/growerp/moqui/runtime/component/growerp/entity/GrowerpMenuViewEntities.xml`:

```xml
<view-entity entity-name="MenuConfigurationView" package="growerp.menu">
  <member-entity entity-alias="MC" entity-name="MenuConfiguration"/>
  <member-entity entity-alias="UA" entity-name="moqui.security.UserAccount" join-from-alias="MC" join-optional="true">
    <key-map field-name="userLoginId"/>
  </member-entity>
  <alias-all entity-alias="MC"/>
  <alias name="username" entity-alias="UA" field="username"/>
</view-entity>

<view-entity entity-name="MenuItemView" package="growerp.menu">
  <member-entity entity-alias="MI" entity-name="MenuItem"/>
  <member-entity entity-alias="MC" entity-name="MenuConfiguration" join-from-alias="MI">
    <key-map field-name="menuConfigurationId"/>
  </member-entity>
  <member-entity entity-alias="PMI" entity-name="MenuItem" join-from-alias="MI" join-optional="true">
    <key-map field-name="parentMenuItemId" related="menuItemId"/>
  </member-entity>
  <alias-all entity-alias="MI"/>
  <alias name="configAppId" entity-alias="MC" field="appId"/>
  <alias name="configName" entity-alias="MC" field="name"/>
  <alias name="parentTitle" entity-alias="PMI" field="title"/>
</view-entity>
```

---

#### [NEW] REST Services

Create services in `/home/hans/growerp/moqui/runtime/component/growerp/service/growerp/100/MenuConfigurationServices100.xml`:

- `GET /rest/s1/growerp/100/MenuConfiguration` - Get menu configuration (user-specific or default)
- `POST /rest/s1/growerp/100/MenuConfiguration` - Create user menu configuration
- `PATCH /rest/s1/growerp/100/MenuConfiguration/{menuConfigurationId}` - Update menu configuration
- `DELETE /rest/s1/growerp/100/MenuConfiguration/{menuConfigurationId}` - Delete user menu configuration
- `GET /rest/s1/growerp/100/MenuItem` - Get menu items for a configuration
- `POST /rest/s1/growerp/100/MenuItem` - Create menu item
- `PATCH /rest/s1/growerp/100/MenuItem/{menuItemId}` - Update menu item
- `DELETE /rest/s1/growerp/100/MenuItem/{menuItemId}` - Delete menu item

---

### Application Packages

#### [NEW] [go_router_config.dart](file:///home/hans/growerp/flutter/packages/admin/lib/go_router_config.dart)

Create GoRouter configuration for the admin app:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ... imports

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminDbForm(),
      ),
      GoRoute(
        path: '/companies',
        builder: (context, state) => const CompaniesShell(),
        routes: [
          GoRoute(
            path: 'company',
            builder: (context, state) => ShowCompanyDialog(
              Company(role: Role.company),
              dialog: false,
            ),
          ),
          GoRoute(
            path: 'employees',
            builder: (context, state) => const UserList(
              key: Key('Employee'),
              role: Role.company,
            ),
          ),
          GoRoute(
            path: 'website',
            builder: (context, state) => const WebsiteDialog(),
          ),
        ],
      ),
      // Add all other routes from menu configuration
      // CRM routes
      GoRoute(
        path: '/crm',
        builder: (context, state) => const CrmShell(),
        routes: [
          GoRoute(
            path: 'tasks',
            builder: (context, state) => const ActivityList(ActivityType.todo),
          ),
          GoRoute(
            path: 'opportunities',
            builder: (context, state) => const OpportunityList(),
          ),
          // ... more CRM routes
        ],
      ),
      // ... more top-level routes
    ],
    redirect: (context, state) {
      final authBloc = context.read<AuthBloc>();
      final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;
      
      if (!isAuthenticated && state.location != '/') {
        return '/';
      }
      return null;
    },
  );
}
```

---

#### [DELETE] [router.dart](file:///home/hans/growerp/flutter/packages/admin/lib/router.dart)

Delete the old Navigator 1.0 router file.

---

#### [MODIFY] [menu_options.dart](file:///home/hans/growerp/flutter/packages/admin/lib/menu_options.dart)

Replace with routing-based `MenuConfiguration`:

```dart
MenuConfiguration getMenuConfiguration(BuildContext context) {
  return MenuConfiguration(
    appId: 'admin',
    name: 'Admin Menu',
    description: 'Default admin application menu structure',
    menuItems: [
      MenuItem(
        image: 'packages/growerp_core/images/dashBoardGrey.png',
        selectedImage: 'packages/growerp_core/images/dashBoard.png',
        title: CoreLocalizations.of(context)!.main,
        route: '/', // route to dashboard
        userGroups: [UserGroup.admin, UserGroup.employee],
      ),
      MenuItem(
        image: 'packages/growerp_core/images/companyGrey.png',
        selectedImage: 'packages/growerp_core/images/company.png',
        title: CoreLocalizations.of(context)!.organization,
        route: '/companies',
        userGroups: [UserGroup.admin, UserGroup.employee],
        children: [
          MenuItem(
            title: CoreLocalizations.of(context)!.company,
            iconName: 'home',
            route: '/companies/company',
          ),
          MenuItem(
            title: CoreLocalizations.of(context)!.employees,
            iconName: 'school',
            route: '/companies/employees',
          ),
          MenuItem(
            title: CoreLocalizations.of(context)!.website,
            iconName: 'webhook',
            route: '/companies/website',
          ),
        ],
      ),
      // ... rest of menu items with routes instead of widgets
    ],
  );
}
```

**Key changes:**
- All `child` and `form` widgets replaced with `route` paths
- All `Icon` objects replaced with `iconName` strings
- Delete old `getMenuOptions()` and `menuOptions()` functions entirely
- Update router to handle all new routes

Similar changes for:
- [acct_menu_options.dart](file:///home/hans/growerp/flutter/packages/admin/lib/acct_menu_options.dart)
- [menu_options.dart](file:///home/hans/growerp/flutter/packages/freelance/lib/menu_options.dart)
- [menu_options.dart](file:///home/hans/growerp/flutter/packages/health/lib/menu_options.dart)
- [menu_option_data.dart](file:///home/hans/growerp/flutter/packages/hotel/lib/menu_option_data.dart)
- [menu_options.dart](file:///home/hans/growerp/flutter/packages/support/lib/menu_options.dart)

#### [MODIFY] Router Files

Update router in each app to handle new routes:

- Add routes for all tab content (e.g., `/companies/company`, `/companies/employees`, `/companies/website`)
- Ensure all routes return appropriate widgets
- Remove any route arguments that were passing widgets directly

---

---

### User Menu Customization Feature

#### [NEW] Menu Customization UI

Create a new menu customization screen in `growerp_core`:

- **Location**: `lib/src/domains/common/views/menu_customization_form.dart`
- **Features**:
  - Display current menu structure in a tree view
  - Allow drag-and-drop reordering of menu items
  - Allow hiding/showing menu items
  - Allow renaming menu items (title only, not functionality)
  - Save button to persist changes to backend
  - Reset button to restore default app menu

#### [NEW] Menu Configuration BLoC

Create BLoC for menu configuration management:

- **Location**: `lib/src/domains/common/blocs/menu_config_bloc.dart`
- **Events**:
  - `MenuConfigLoad` - Load menu configuration (user-specific or default)
  - `MenuConfigUpdate` - Update menu configuration
  - `MenuConfigReset` - Reset to default
  - `MenuItemReorder` - Reorder menu items
  - `MenuItemToggleVisibility` - Show/hide menu item
- **States**:
  - `MenuConfigInitial`
  - `MenuConfigLoading`
  - `MenuConfigLoaded`
  - `MenuConfigError`

#### [MODIFY] REST Client

Add menu configuration endpoints to `growerp_models/lib/src/rest_client.dart`:

```dart
@GET('/s1/growerp/100/MenuConfiguration')
Future<MenuConfiguration> getMenuConfiguration(
  @Query('appId') String appId,
  @Query('userLoginId') String? userLoginId,
);

@POST('/s1/growerp/100/MenuConfiguration')
Future<MenuConfiguration> createMenuConfiguration(
  @Body() MenuConfiguration menuConfiguration,
);

@PATCH('/s1/growerp/100/MenuConfiguration/{menuConfigurationId}')
Future<MenuConfiguration> updateMenuConfiguration(
  @Path() String menuConfigurationId,
  @Body() MenuConfiguration menuConfiguration,
);

@DELETE('/s1/growerp/100/MenuConfiguration/{menuConfigurationId}')
Future<void> deleteMenuConfiguration(
  @Path() String menuConfigurationId,
);
```

---

## Verification Plan

### Automated Tests

1. **Model Tests**
   ```bash
   cd /home/hans/growerp/flutter/packages/growerp_models
   flutter test
   ```
   - Verify `MenuItem` serialization/deserialization
   - Verify `MenuConfiguration` serialization/deserialization
   - Test conversion from `MenuOption` to `MenuItem`
   - Test conversion from `TabItem` to `MenuItem`

2. **Core Integration Tests**
   ```bash
   cd /home/hans/growerp/flutter/packages/growerp_core/example
   flutter test integration_test/core_test.dart
   ```
   - Verify menu rendering with new `MenuItem` model
   - Test navigation between menu items
   - Test tab switching functionality

3. **Admin App Integration Tests**
   ```bash
   cd /home/hans/growerp/flutter/packages/admin/example
   flutter test integration_test/
   ```
   - Verify all menu items render correctly
   - Test navigation through all menu options
   - Verify tab functionality in CRM, Catalog, Orders, and Inventory sections

### Manual Verification

1. **Desktop Layout**
   - Run admin app: `cd /home/hans/growerp/flutter/packages/admin && flutter run -d linux`
   - Verify navigation rail displays all menu items
   - Click through each menu item and verify correct page loads
   - For menu items with tabs (Organization, CRM, Catalog, Orders, Inventory):
     - Verify tab bar appears at top
     - Click each tab and verify correct content loads
     - Verify floating action buttons appear where expected

2. **Mobile Layout**
   - Run admin app on mobile emulator: `cd /home/hans/growerp/flutter/packages/admin && flutter run -d <device>`
   - Verify drawer menu displays all menu items
   - For menu items with tabs:
     - Verify bottom navigation bar appears
     - Tap each tab and verify correct content loads
     - Verify floating action buttons work correctly

3. **User Group Filtering**
   - Login as different user types (admin, employee)
   - Verify only authorized menu items are displayed
   - Verify unauthorized items are hidden

4. **Other Apps**
   - Repeat desktop and mobile verification for:
     - Freelance app
     - Health app
     - Hotel app
     - Support app

### User Customization Tests

1. **Default Menu Loading**
   - Verify default app menu loads correctly for new users
   - Verify menu items display in correct order

2. **User Menu Customization**
   - Create a custom menu configuration for a user
   - Verify custom menu persists across sessions
   - Verify custom menu loads instead of default

3. **Menu Customization UI**
   - Test drag-and-drop reordering
   - Test hiding/showing menu items
   - Test renaming menu items
   - Test save functionality
   - Test reset to default functionality

4. **Multi-User Testing**
   - Verify different users can have different menu configurations
   - Verify changes to one user's menu don't affect others
   - Verify default menu changes affect users without custom menus
