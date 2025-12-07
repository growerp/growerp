# Sidebar and Tab Navigation Fixes

## Problem
The left navigation bar (sidebar/drawer) was displaying all menu items, including tab items (children). This cluttered the interface and duplicated navigation options available in the tabs. Additionally, navigating directly to a tab URL via deep linking might not have correctly highlighted the parent item in the sidebar.

## Solution

### 1. Filtered Sidebar Items
Modified `DisplayMenuOption` in `growerp_core` to strictly filter the sidebar list:
- **Rule:** Only `MenuItem`s with `parentMenuItemId == null` are added to the sidebar list.
- **Result:** Tabs (e.g., "Employees", "Website") no longer appear in the left drawer or navigation rail. Only top-level sections (e.g., "Organization", "CRM") are shown.

### 2. Improved Sidebar Highlighting
The logic for determining the active sidebar item has been updated:
- If the current route corresponds to a top-level item, that item is highlighted.
- If the current route corresponds to a **child item (tab)**, the system identifies the **parent** and highlights the parent in the sidebar.
  - *Example:* Navigating to `/companies/employees` highlights "Organization" in the sidebar.

### 3. Correct Tab Selection
The tab bar initialization logic now respects deep linking:
- On load, the system checks if the current route matches any of the available tabs.
- If a match is found, that tab is automatically selected as the initial active tab.
- This ensures that reloading the page at `/companies/employees` correctly selects the "Employees" tab instead of defaulting to the first tab.

### 4. Enabled Desktop Tab Navigation
Added an `onTap` handler to the `TabBar` widget (used on Desktop/Tablet layouts):
- Previously, clicking tabs on desktop might strictly change the view index without updating the URL (unless relying on `TabBarView` which was using a shared `child`).
- Now, clicking a tab explicitly calls `context.go(tab.route!)`, ensuring proper routing and URL updates.

## Files Modified
- `growerp_core/lib/src/templates/display_menu_option.dart`: Complete refactor of `_initialize` method and update to `_buildTabbedPage`.

## Verification
1. Open the Admin App.
2. Check the left sidebar (Drawer or Navigation Rail).
3. **Verify:** It should ONLY show "Main", "Organization", "CRM", "Catalog", "Orders", "Inventory", "Accounting", "About". It should NOT show items like "Employees" or "Sales orders".
4. Click "Organization".
5. **Verify:** Top tabs appear: "Company", "Employees", "Website".
6. Click "Employees".
7. **Verify:** URL changes to `/companies/employees`. "Employees" tab is selected. Sidebar still highlights "Organization".
8. Reload the page.
9. **Verify:** App loads at `/companies/employees`, "Organization" is highlighted in sidebar, "Employees" tab is active.
