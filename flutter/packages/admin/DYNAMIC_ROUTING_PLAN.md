# Dynamic Routing Implementation Plan

This plan details how to transition from a static `go_router_config.dart` to a dynamic routing system driven by backend `MenuConfiguration`.

## 1. Widget Registry
Since backend data provides strings (e.g., widget names), we need a reliable way to map these strings to actual Flutter widgets.

### **Action Item:** Create `WidgetRegistry` class
- **Function**: `Widget getWidget(String widgetName, Map<String, dynamic> params)`
- **Structure**: A static map or factory lookup.
```dart
class WidgetRegistry {
  static Widget getWidget(String name, [Map<String, dynamic>? args]) {
    switch (name) {
      case 'UserList':
        return UserList(role: _parseRole(args?['role']));
      case 'FinDocList':
        return FinDocList(
             sales: args?['sales'] ?? true, 
             docType: _parseDocType(args?['docType'])
        );
      // ... default case
      default:
        return const Text('Widget not found');
    }
  }
}
```

## 2. Bootstrapping (App Initialization)
The application needs to load the menu configuration *before* the main Router is fully built or effectively usable, OR the Router needs to react to state changes.

### **Approach: Splash Screen Loader**
1.  **Initial Route**: `/` points to a `SplashScreen`.
2.  **Logic**:
    - `SplashScreen` dispatches `MenuConfigLoad()`.
    - Listens for `MenuConfigState.success`.
    - Once loaded, it redirects to the Dashboard.
    - **Crucial**: The `GoRouter` instance itself checks `MenuConfigState` and rebuilds routes if needed (GoRouter 5/6+ supports `refreshListenable`).

### **Alternative: Runtime Route Building**
Since `GoRouter` construction happens at app start, we might need to modify `createAdminRouter` to accept a `MenuConfiguration` object.
1.  **Fetch Config**: In `main.dart`, before `runApp`, or use a `FutureBuilder` returning the `MaterialApp.router`.
2.  **Build Routes**: Iterate recursively through `MenuConfiguration.menuItems`.

## 3. Dynamic Route Generation Logic

### **Algorithm**
```dart
List<RouteBase> buildDynamicRoutes(MenuConfiguration config) {
  List<RouteBase> routes = [];
  
  // 1. Identify Shells (Top-level configs or implicit)
  // For Admin, we essentially have ONE config but maybe split by 'root' items?
  // Current structure has explicit Shells.
  
  // 2. Iterate Items
  for (var item in config.menuItems) {
     if (item.route != null) {
        routes.add(
           GoRoute(
             path: item.route!,
             builder: (context, state) => WidgetRegistry.getWidget(item.widgetName),
           )
        );
     }
  }
  return routes;
}
```

## 4. Handling Dual-Shell (Admin vs Accounting)
The current static config has two `ShellRoutes`. The dynamic system needs to know which items belong to which shell.
- **Option A**: Two separate `MenuConfiguration` IDs from backend (`ADMIN_DEFAULT`, `ACCOUNTING_DEFAULT`).
- **Option B**: One config, but items have a "group" concept.

**Proposal**: Fetch ALL configs.
- `routes` List gets populated by iterating over known Config IDs.
- `ShellRoute` builders use the specific `MenuConfiguration` object.

## 5. Proposed Code Structure Changes

1.  **`admin/lib/router_builder.dart`** (New File)
    - Contains logic to convert `List<MenuConfiguration>` -> `GoRouter`.
2.  **`main.dart` Update**
    - Initialize `AuthBloc` AND `MenuConfigBloc`.
    - Use `FutureBuilder` or similar to wait for Menu Config?
    - **Better**: `GoRouter` with `refreshListenable` pointing to `MenuConfigBloc`.
      - When Bloc state changes (config loaded), Router refreshes.
      - **Challenge**: `routes` property of `GoRouter` is final. You cannot change routes dynamically easily without creating a NEW Router instance.
      - **Solution**: Use `MaterialApp.router(routerConfig: _router)`. Rebuild `MaterialApp` with a NEW `_router` when Bloc state changes?
      - Or use a root `ShellRoute` that handles the "Loading" state and acts as a wrapper.

## 6. Step-by-Step Implementation Plan

1.  **Create Registry**: Implement `admin/lib/widget_registry.dart` mapping all current widgets.
2.  **Modify Backend Data**: Ensure backend has valid `widgetName` and `route` for all items (Seeding).
3.  **Bloc Integration**:
    - Update `createAdminRouter` to accept `MenuConfiguration`.
    - In `main.dart`, use a `BlocBuilder<MenuConfigBloc, ...>` to wrap `MaterialApp.router`.
    - When config loads, `createAdminRouter(config)` is called, creating a fresh Router with dynamic routes.
    - While loading, show `MaterialApp(home: SplashScreen)`.

## 7. Migration Strategy
1.  Keep `go_router_config.dart` as fallback.
2.  Implement `widget_registry.dart`.
3.  Test loading *one* route dynamically.
4.  Switch `main.dart` to fetch config.
