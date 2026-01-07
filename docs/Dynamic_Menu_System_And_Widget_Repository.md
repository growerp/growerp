# Dynamic Menu System and Widget Repository

**Last Updated:** January 2026  
**Status:** ✅ Production Ready  
**Package:** `growerp_core` & `growerp_models`

---

## Overview

GrowERP's navigation system is built on a powerful combination of **dynamic menus** and a **composable widget registry**. This architecture enables:

- **Dynamic menu configuration** stored in the backend database
- **Composable widget registry** allowing packages to register their screens
- **Role-based access control** for menu visibility
- **Two router patterns**: Static for simple apps, Dynamic for full-featured apps

This document covers both the **full implementation** (used in production apps like Admin) and the **simple implementation** (used in package example apps).

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Models](#data-models)
3. [Widget Registry](#widget-registry)
4. [Dynamic Router (Full Apps)](#dynamic-router-full-apps)
5. [Static Router (Simple Example Apps)](#static-router-simple-example-apps)
6. [Example Implementations](#example-implementations)
7. [When to Use Each Pattern](#when-to-use-each-pattern)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Application Layer                           │
├─────────────────────────────────────────────────────────────────────┤
│  Full Apps (Admin, Hotel, etc.)    │  Example Apps (package tests)  │
│  ┌─────────────────────────────┐   │  ┌─────────────────────────────┐│
│  │ Dynamic Menu from Backend   │   │  │ Static MenuConfiguration    ││
│  │ + MenuConfigBloc            │   │  │ (hardcoded in main.dart)    ││
│  │ + createDynamicAppRouter()  │   │  │ + createStaticAppRouter()   ││
│  └─────────────────────────────┘   │  └─────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────┤
│                        Common Components                              │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ WidgetRegistry: Maps widget names → Widget builders              │ │
│  │ DisplayMenuOption: Renders navigation UI (rail/drawer + tabs)    │ │
│  │ MenuConfiguration → MenuOption → MenuItem (hierarchy)            │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Models

### MenuConfiguration

The top-level container for an application's menu structure.

```dart
class MenuConfiguration {
  final String? menuConfigurationId;  // Unique ID
  final String appId;                 // Application identifier (e.g., 'admin')
  final String name;                  // Human-readable name
  final String? description;          // Optional description
  final String? userId;               // For user-specific overrides (null = default)
  final bool isActive;                // Enable/disable configuration
  final DateTime? createdDate;        // Audit timestamp
  final List<MenuOption> menuOptions; // Main menu entries
}
```

**Key Features:**
- `appId` identifies which application this config belongs to
- `userId` allows per-user menu customization (null = app default)
- `menuOptions` contains the main navigation items

### MenuOption

Represents a main menu entry (navigation rail item or drawer item).

```dart
class MenuOption {
  final String? menuOptionId;         // Unique ID
  final String? menuConfigurationId;  // Parent configuration
  final String? itemKey;              // Key for Widget testing
  final String title;                 // Display title
  final String? route;                // GoRouter path (e.g., '/products')
  final String? iconName;             // Icon from registry (e.g., 'business')
  final String? widgetName;           // Widget name in WidgetRegistry
  final String? image;                // Image asset path for nav rail
  final String? selectedImage;        // Selected state image
  final List<UserGroup>? userGroups;  // Access control (admin, employee, etc.)
  final int sequenceNum;              // Display order
  final bool isActive;                // Enable/disable option
  final List<MenuItem>? children;     // Sub-items (tabs)
}
```

**Key Features:**
- `widgetName` references a widget registered in `WidgetRegistry`
- `children` contains `MenuItem` sub-tabs for tabbed interfaces
- `userGroups` controls visibility based on user role
- `image`/`selectedImage` for navigation rail icons

### MenuItem

Represents a tab or child item within a MenuOption.

```dart
class MenuItem {
  final String menuItemId;    // Unique ID
  final String title;         // Tab label
  final String? iconName;     // Icon for tab bar
  final String? widgetName;   // Widget name in WidgetRegistry
  final String? image;        // Optional image
  final bool isActive;        // Enable/disable item
  final int? sequenceNum;     // Display order within parent
}
```

**Example Hierarchy:**
```
MenuConfiguration (Admin App)
├── MenuOption (Main Dashboard)
│   └── route: '/'
│   └── widgetName: 'AdminDashboard'
├── MenuOption (Catalog)
│   └── route: '/catalog'
│   └── children:
│       ├── MenuItem (Products) → widgetName: 'ProductList'
│       ├── MenuItem (Categories) → widgetName: 'CategoryList'
│       └── MenuItem (Assets) → widgetName: 'AssetList'
└── MenuOption (Users)
    └── route: '/users'
    └── widgetName: 'UserList'
```

---

## Widget Registry

The `WidgetRegistry` is a composable system that maps widget names (strings) to widget builder functions. This decouples the menu configuration from specific widget implementations.

### Core Concept

```dart
typedef GrowerpWidgetBuilder = Widget Function(Map<String, dynamic>? args);

class WidgetRegistry {
  static final Map<String, WidgetMetadata> _widgets = {};
  
  /// Register widgets from a package
  static void register(Map<String, GrowerpWidgetBuilder> widgets);
  
  /// Get a widget by name
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]);
  
  /// Check if widget exists
  static bool hasWidget(String widgetName);
}
```

### Package Widget Registration

Each package exports a function that returns its widget mappings:

```dart
// In growerp_catalog package
Map<String, GrowerpWidgetBuilder> getCatalogWidgets() => {
  'ProductList': (args) => ProductList(key: getKeyFromArgs(args)),
  'ProductDialog': (args) => ProductDialog(product: args?['product']),
  'CategoryList': (args) => CategoryList(key: getKeyFromArgs(args)),
  // ... more widgets
};

// In growerp_user_company package
Map<String, GrowerpWidgetBuilder> getUserCompanyWidgets() => {
  'UserList': (args) => UserList(
    key: getKeyFromArgs(args),
    role: parseRole(args?['role']),
  ),
  'CompanyList': (args) => CompanyList(
    key: getKeyFromArgs(args),
    role: parseRole(args?['role']),
  ),
  // ... more widgets
};
```

### App-Level Composition

Applications compose widgets from all their dependent packages:

```dart
// In admin/lib/main.dart
List<Map<String, GrowerpWidgetBuilder>> adminWidgetRegistrations = [
  getUserCompanyWidgets(),
  getCatalogWidgets(),
  getInventoryWidgets(),
  getOrderAccountingWidgets(),
  getActivityWidgets(),
  getMarketingWidgets(),
  getOutreachWidgets(),
  getSalesWidgets(),
  getWebsiteWidgets(),
  // App-specific widgets
  {
    'AdminDashboard': (args) => const AdminDashboardContent(),
    'AccountingForm': (args) => const AccountingForm(),
  },
];
```

### Widget Metadata (for AI Navigation)

The registry supports enhanced metadata for AI-assisted navigation:

```dart
class WidgetMetadata {
  final String widgetName;        // e.g., 'SalesInvoiceList'
  final String description;       // Human-readable description
  final List<String> keywords;    // AI matching (e.g., ['invoice', 'AR'])
  final Map<String, String> parameters;  // Parameter docs
  final GrowerpWidgetBuilder builder;
}

// Register with metadata for AI discovery
WidgetRegistry.registerWithMetadata(WidgetMetadata(
  widgetName: 'SalesInvoiceList',
  description: 'List of outgoing sales invoices',
  keywords: ['invoice', 'sales', 'AR', 'receivable'],
  builder: (args) => const FinDocList(finDocType: FinDocType.invoice),
));
```

---

## Dynamic Router (Full Apps)

The **Dynamic Router** pattern is used by full production applications that load their menu configuration from the backend.

### Overview

```dart
GoRouter createDynamicAppRouter(
  List<MenuConfiguration> configurations, {
  required DynamicRouterConfig config,
  GlobalKey<NavigatorState>? rootNavigatorKey,
});
```

### Configuration

```dart
class DynamicRouterConfig {
  final String? mainConfigId;           // e.g., 'ADMIN_DEFAULT'
  final String? accountingRootOptionId; // e.g., 'ADMIN_ACCOUNTING'
  final Widget Function()? dashboardBuilder;
  final Widget Function(String, [Map<String, dynamic>?]) widgetLoader;
  final String appTitle;
  final bool hasAccountingSubmenu;      // Enable accounting shell route
  final Widget Function(MenuConfiguration)? dashboardFabBuilder;
}
```

### Key Features

1. **Backend Menu Loading**: Uses `MenuConfigBloc` to fetch configuration from REST API
2. **Accounting Submenu**: Supports nested accounting submenu with its own shell
3. **Dynamic Route Generation**: Creates routes from `MenuOption.route` values
4. **Widget Loading**: Uses `WidgetRegistry.getWidget()` to instantiate widgets

### Full App Example (Admin)

```dart
class _AdminAppState extends State<AdminApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'admin');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _menuConfigBloc,
      child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
        builder: (context, state) {
          GoRouter router;

          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                mainConfigId: 'ADMIN_DEFAULT',
                accountingRootOptionId: 'ADMIN_ACCOUNTING',
                dashboardBuilder: () => const AdminDashboardContent(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'GrowERP Administrator',
                hasAccountingSubmenu: true,
              ),
            );
          } else {
            // Show splash screen while loading
            router = GoRouter(routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => AppSplashScreen.simple(
                  appTitle: 'GrowERP Administrator',
                  appId: 'admin',
                ),
              ),
            ]);
          }

          return TopApp(
            router: router,
            widgetRegistrations: adminWidgetRegistrations,
            // ... other config
          );
        },
      ),
    );
  }
}
```

---

## Static Router (Simple Example Apps)

The **Static Router** pattern is used by package example apps that don't need backend configuration. The menu is defined directly in code.

### Overview

```dart
GoRouter createStaticAppRouter({
  required MenuConfiguration menuConfig,
  required String appTitle,
  required Widget Function(String route) widgetBuilder,
  Widget? dashboard,
  List<RouteBase> additionalRoutes = const [],
  Widget Function(String widgetName, Map<String, dynamic> args)? tabWidgetLoader,
});
```

### Key Features

1. **No Backend Required**: Menu defined as `const` in Dart code
2. **Simple Widget Builder**: Route-based widget mapping
3. **Tab Support**: Optional `tabWidgetLoader` for tabbed interfaces
4. **Additional Routes**: Support for dialog routes, detail screens

### Simple Example (Catalog)

```dart
// Static menu configuration
const catalogMenuConfig = MenuConfiguration(
  menuConfigurationId: 'CATALOG_EXAMPLE',
  appId: 'catalog_example',
  name: 'Catalog Example Menu',
  menuOptions: [
    MenuOption(
      menuOptionId: 'CATALOG_MAIN',
      title: 'Catalog',
      route: '/',
      iconName: 'category',
      widgetName: 'CatalogDashboard',
    ),
    MenuOption(
      menuOptionId: 'CATALOG_PRODUCTS',
      title: 'Products',
      route: '/products',
      iconName: 'products',
      widgetName: 'ProductList',
    ),
    MenuOption(
      menuOptionId: 'CATALOG_CATEGORIES',
      title: 'Categories',
      route: '/categories',
      iconName: 'folder',
      widgetName: 'CategoryList',
    ),
  ],
);

// Create router
GoRouter createCatalogExampleRouter() {
  return createStaticAppRouter(
    menuConfig: catalogMenuConfig,
    appTitle: 'GrowERP Catalog Example',
    dashboard: const CatalogDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/products' => const ProductList(),
      '/categories' => const CategoryList(),
      _ => const CatalogDashboard(),
    },
  );
}
```

### Tabbed Example (User Company)

For apps with tabbed interfaces:

```dart
const userCompanyMenuConfig = MenuConfiguration(
  menuConfigurationId: 'USER_COMPANY_EXAMPLE',
  appId: 'user_company_example',
  name: 'User & Company Example Menu',
  menuOptions: [
    MenuOption(
      menuOptionId: 'UC_COMPANIES',
      title: 'Companies',
      route: '/companies',
      iconName: 'business',
      widgetName: 'CompanyList',
      children: [
        MenuItem(
          menuItemId: 'UC_COMP_MAIN',
          title: 'Main Company',
          iconName: 'home_work',
          widgetName: 'CompanyListMain',
        ),
        MenuItem(
          menuItemId: 'UC_COMP_SUPPLIER',
          title: 'Suppliers',
          iconName: 'local_shipping',
          widgetName: 'CompanyListSupplier',
        ),
        MenuItem(
          menuItemId: 'UC_COMP_CUSTOMER',
          title: 'Customers',
          iconName: 'storefront',
          widgetName: 'CompanyListCustomer',
        ),
      ],
    ),
    // ... more options
  ],
);

// Tab widget loader
Widget loadTabWidget(String widgetName, Map<String, dynamic> args) {
  switch (widgetName) {
    case 'CompanyListMain':
      return ShowCompanyDialog(Company(role: Role.company), dialog: false);
    case 'CompanyListSupplier':
      return const CompanyList(role: Role.supplier);
    case 'CompanyListCustomer':
      return const CompanyList(role: Role.customer);
    default:
      return Center(child: Text('Unknown widget: $widgetName'));
  }
}

GoRouter createUserCompanyExampleRouter() {
  return createStaticAppRouter(
    menuConfig: userCompanyMenuConfig,
    appTitle: 'GrowERP User & Company Example',
    dashboard: const UserCompanyDashboard(),
    tabWidgetLoader: loadTabWidget,  // Enable tab support
    widgetBuilder: (route) => switch (route) {
      '/companies' => ShowCompanyDialog(Company(role: Role.company), dialog: false),
      '/users' => const UserList(role: Role.company),
      _ => const UserCompanyDashboard(),
    },
  );
}
```

---

## Example Implementations

### Full App Examples

| Application | Location | Features |
|-------------|----------|----------|
| Admin | `flutter/packages/admin/` | Dynamic menu, accounting submenu, all packages |
| Hotel | `flutter/packages/hotel/` | Dynamic menu, hospitality-focused |
| Freelance | `flutter/packages/freelance/` | Dynamic menu, simplified feature set |
| Support | `flutter/packages/support/` | Dynamic menu, support-focused |

### Simple Example Apps

| Package | Example Location | Features |
|---------|------------------|----------|
| growerp_core | `growerp_core/example/` | Minimal, dynamic with fallback |
| growerp_catalog | `growerp_catalog/example/` | Static, products/categories |
| growerp_user_company | `growerp_user_company/example/` | Static, tabbed interface |
| growerp_inventory | `growerp_inventory/example/` | Static, locations/assets |
| growerp_sales | `growerp_sales/example/` | Static, opportunities |

---

## When to Use Each Pattern

### Use Dynamic Router When:

- ✅ Building a full production application
- ✅ Need backend-stored menu configuration
- ✅ Want user-customizable menus
- ✅ Have multiple menu configurations (main + accounting)
- ✅ Need role-based menu filtering from backend

### Use Static Router When:

- ✅ Building a package example app
- ✅ Running integration tests
- ✅ Don't need backend dependency
- ✅ Menu structure is fixed and simple
- ✅ Quick prototyping

---

## Key Files Reference

### Core Infrastructure

| File | Purpose |
|------|---------|
| `growerp_models/lib/src/models/menu_configuration_model.dart` | MenuConfiguration model |
| `growerp_models/lib/src/models/menu_option_model.dart` | MenuOption model |
| `growerp_models/lib/src/models/menu_item_model.dart` | MenuItem model |
| `growerp_core/lib/src/services/widget_registry.dart` | WidgetRegistry service |
| `growerp_core/lib/src/templates/dynamic_router_builder.dart` | Dynamic router builder |
| `growerp_core/lib/src/templates/static_router_builder.dart` | Static router builder |
| `growerp_core/lib/src/templates/display_menu_option.dart` | Menu rendering widget |

### Example Apps

| File | Pattern |
|------|---------|
| `admin/lib/main.dart` | Dynamic router pattern |
| `growerp_core/example/lib/main.dart` | Dynamic with fallback |
| `growerp_catalog/example/lib/main.dart` | Static router pattern |
| `growerp_user_company/example/lib/main.dart` | Static with tabs |

---

## Summary

The GrowERP menu and widget system provides:

1. **Flexibility**: Choose between dynamic (backend) or static (code) menu configuration
2. **Composability**: Packages register their widgets independently
3. **Separation of Concerns**: Menu structure is separate from widget implementation
4. **Testability**: Static configs enable easy integration testing
5. **Customization**: Users can customize their menu (with dynamic router)

For new development:
- **Building a package?** → Use static router in example app
- **Building a full app?** → Use dynamic router with MenuConfigBloc
- **Adding widgets?** → Export a `getXxxWidgets()` function from your package
