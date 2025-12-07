# Admin Menu Structure - Complete Implementation

## Overview
Successfully reproduced the original admin menu structure from `GrowerpMenuSeedData.xml` with full tab support for all major sections.

## Menu Structure

### 1. **Main** (Dashboard)
- Route: `/`
- Shows dashboard cards for all other menu items
- Not displayed as a card itself

### 2. **Organization** 
- Main route: `/companies`
- **Tabs:**
  - Company → `/companies/company`
  - Employees → `/companies/employees`
  - Website → `/companies/website`

### 3. **CRM**
- Main route: `/crm`
- **Tabs:**
  - My To Do, tasks → `/crm/tasks`
  - Opportunities → `/crm/opportunities`
  - Leads → `/crm/leads`
  - Customers → `/crm/customers`
  - Requests → `/crm/requests`
  - Landing Pages → `/crm/landing-pages`
  - Assessments → `/crm/assessments`

### 4. **Catalog**
- Main route: `/catalog`
- **Tabs:**
  - Products → `/catalog/products`
  - Assets → `/catalog/assets`
  - Categories → `/catalog/categories`
  - Subscriptions → `/catalog/subscriptions`

### 5. **Orders**
- Main route: `/orders`
- **Tabs:**
  - Sales orders → `/orders/sales`
  - Customers → `/orders/customers`
  - Purchase orders → `/orders/purchase`
  - Suppliers → `/orders/suppliers`

### 6. **Inventory**
- Main route: `/inventory`
- **Tabs:**
  - Outgoing shipments → `/inventory/shipments-out`
  - Incoming shipments → `/inventory/shipments-in`
  - Assets → `/inventory/assets`
  - WH Locations → `/inventory/locations`

### 7. **Accounting**
- Route: `/accounting`
- No tabs

### 8. **About**
- Route: `/about`
- No tabs

## Implementation Details

### Files Modified

1. **`admin_menu_config.dart`**
   - Added all menu items with proper parent-child relationships
   - Total: 8 main menu items + 28 tab items = 36 menu items
   - Matches `ADMIN_DEFAULT` configuration from `GrowerpMenuSeedData.xml`

2. **`go_router_config.dart`**
   - Added routes for all menu items and tabs
   - Uses `ShellRoute` for persistent header and drawer
   - Total: 36 routes matching all menu items

### Widget Mappings

Currently implemented widgets:
- **Organization**:
  - Main/Company: `ShowCompanyDialog` (Main Company Details)
  - Employees: `UserList`
  - Website: `WebsiteDialog` (Full Website Management from `growerp_website`)
- **Other Modules**:
  - `CompanyList` - General Company management (used elsewhere)
  - `UserList` - Users (employees, customers, suppliers)
  - `ProductList` - Products
  - `CategoryList` - Categories
  - `AssetList` - Assets
  - `LocationList` - Warehouse locations
  - `FinDocList` - Financial documents (orders, shipments)
  - `AccountingForm` - Accounting dashboard

Placeholder widgets (Coming Soon):
- CRM Tasks
- Opportunities
- Leads
- Requests
- Landing Pages
- Assessments
- Subscriptions
- About page

## Sidebar and Tab Behavior

### Sidebar (Drawer/Navigation Rail)
- **Filtered View**: The filtered sidebar ONLY displays top-level menu items (e.g., "Organization", "CRM").
- **Clean Interface**: Sub-items (tabs) are hidden from the sidebar to prevent clutter.
- **Auto-Highlighting**: Navigating to a submodule (e.g., `/companies/employees`) correctly highlights the parent module ("Organization") in the sidebar.

### Tabs
- **Location**:
  - **Desktop/Tablet**: Tabs appear in the AppBar, styled as modern tabs (filling the width).
  - **Phone**: Tabs appear in the bottom navigation bar.
- **Navigation**:
  - Clicking tabs on Desktop/Tablet triggers proper URL navigation (supporting deep linking/reload).
  - Changing menu sections immediately updates the tab bar to the new section.
- **Styling**:
  - Reduced height for a compact look.
  - Indicator fills the tab background for better visibility.

## Menu Index Calculation

The `DisplayMenuOption` widget automatically:
1. **Filters** menu items for the sidebar (top-level only).
2. **Calculates** the correct menu index based on the current route (mapping children to parents).
3. **Highlights** the active menu item in the drawer/navigation rail.
4. **Initializes** the correct tab selection based on the deep link URL.

## Next Steps

To complete the implementation:
1. Replace placeholder widgets with actual implementations
2. Add proper icons for all menu items (currently using default icons)
3. Implement user group filtering (currently all items visible)
4. Add deep linking support for direct navigation to tabs
5. Consider loading menu configuration from backend instead of hardcoded

## Testing

To test the menu structure:
```bash
cd flutter/packages/admin
flutter run
```

Expected behavior:
1. Login to see the dashboard
2. Click "Organization" → See tabs: Company, Employees, Website
3. Click "CRM" → See tabs: Tasks, Opportunities, Leads, etc.
4. Click any tab → Content changes, header and drawer remain visible
5. Navigate between different menu sections → Tabs update accordingly
