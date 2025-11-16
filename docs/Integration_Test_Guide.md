# GrowERP Integration Test Guide

**Last Updated:** November 11, 2025  
**Status:** ✅ PRODUCTION-READY

## Overview

GrowERP uses a comprehensive integration testing framework built on Flutter's `integration_test` package. This guide explains how integration tests are structured, how to write new tests, and best practices for maintaining test quality across the GrowERP ecosystem.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Test Framework Components](#test-framework-components)
3. [Example: Lead User Test Walkthrough](#example-lead-user-test-walkthrough)
4. [Writing Integration Tests](#writing-integration-tests)
5. [Test Data Management](#test-data-management)
6. [Running Tests](#running-tests)
7. [Test Helper Classes](#test-helper-classes)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Integration Test Structure

GrowERP's integration tests follow a standardized pattern across all packages:

```
flutter/packages/
├── growerp_core/
│   └── lib/src/domains/common/integration_test/
│       ├── common_test.dart              # Core test utilities
│       └── persist_functions.dart         # Test data persistence
├── growerp_user_company/
│   ├── lib/src/user/integration_test/
│   │   └── user_test.dart                 # Reusable user test methods
│   └── example/integration_test/
│       ├── user_lead_test.dart            # Lead-specific tests
│       ├── user_employee_test.dart        # Employee tests
│       ├── user_customer_test.dart        # Customer tests
│       └── user_supplier_test.dart        # Supplier tests
├── growerp_catalog/
│   └── example/integration_test/
│       ├── product_test.dart
│       └── category_test.dart
└── growerp_order_accounting/
    └── example/integration_test/
        ├── sales_order_test.dart
        └── purchase_order_test.dart
```

### Test Layers

Integration tests in GrowERP are organized into three layers:

1. **Core Layer** (`growerp_core`): Provides fundamental test utilities
   - `CommonTest`: Basic UI interactions (tap, scroll, enter text, etc.)
   - `PersistFunctions`: Save/load test data between test runs

2. **Domain Layer** (domain packages): Provides reusable test methods
   - `UserTest`: User CRUD operations
   - `ProductTest`: Product operations
   - `OrderTest`: Order operations

3. **Test Layer** (`example/integration_test/`): Actual test scenarios
   - Combines domain layer methods into complete workflows
   - Tests end-to-end user scenarios

---

## Test Framework Components

### 1. IntegrationTestWidgetsFlutterBinding

All integration tests start by initializing the integration test binding:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });
  
  testWidgets('Test description', (tester) async {
    // Test implementation
  });
}
```

**Purpose**: Sets up the Flutter testing environment for integration tests that interact with real widgets.

### 2. CommonTest (Core Utilities)

`CommonTest` provides low-level UI interaction methods:

| Method | Purpose | Example |
|--------|---------|---------|
| `startTestApp()` | Launch app with test configuration | `await CommonTest.startTestApp(tester, ...)` |
| `createCompanyAndAdmin()` | Initialize test company and admin user | `await CommonTest.createCompanyAndAdmin(tester)` |
| `selectOption()` | Navigate to menu option | `await CommonTest.selectOption(tester, 'dbCrm', 'UserListLead', '2')` |
| `tapByKey()` | Tap widget by key | `await CommonTest.tapByKey(tester, 'addNewUser')` |
| `enterText()` | Enter text in form field | `await CommonTest.enterText(tester, 'firstName', 'John')` |
| `doNewSearch()` | Search in list view | `await CommonTest.doNewSearch(tester, searchString: 'John')` |
| `logout()` | Log out current user | `await CommonTest.logout(tester)` |
| `dragUntil()` | Scroll until widget visible | `await CommonTest.dragUntil(tester, key: 'loginName')` |
| `getTextField()` | Get text from widget | `String name = CommonTest.getTextField('firstName')` |
| `getTextFormField()` | Get value from form field | `String email = CommonTest.getTextFormField('userEmail')` |

### 3. PersistFunctions (Test Data Management)

`PersistFunctions` enables test data to persist across test runs:

```dart
// Save test data
SaveTest test = SaveTest(
  users: users,
  sequence: 1,
);
await PersistFunctions.persistTest(test);

// Load test data
SaveTest test = await PersistFunctions.getTest();
List<User> users = test.users;
```

**Purpose**: Maintains test state (e.g., generated IDs, email sequences) to enable incremental testing.

### 4. Domain Test Helpers

Domain packages provide reusable test methods for their entities:

**UserTest** (in `growerp_user_company`):
- `selectLeads()`, `selectEmployees()`, `selectCustomers()`, `selectSuppliers()`
- `addUsers()`: Add new users
- `updateUsers()`: Update existing users
- `deleteUsers()`: Delete users
- `checkUsers()`: Verify user data
- `enterUserData()`: Fill user form (handles complex logic like company assignment)

Similar patterns exist for:
- **ProductTest**: Product CRUD operations
- **CategoryTest**: Category management
- **OrderTest**: Order workflows

---

## Example: Lead User Test Walkthrough

Let's examine `user_lead_test.dart` as a complete example:

### Complete Test File

```dart
import 'package:user_company_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/src/user/integration_test/user_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectLeads(WidgetTester tester) async {
    await UserTest.selectUsers(tester, '/users', 'UserListLead', '2');
  }

  testWidgets('''GrowERP user lead test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP user-lead test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    await selectLeads(tester);
    await UserTest.addUsers(tester, leads.sublist(0, 3));
    await UserTest.checkUsers(tester);
    await UserTest.updateUsers(tester, leads.sublist(3, 6));
    await UserTest.checkUsers(tester);
    await UserTest.deleteUsers(tester);
    await CommonTest.logout(tester);
  });
}
```

### Step-by-Step Breakdown

#### 1. Test Setup

```dart
IntegrationTestWidgetsFlutterBinding.ensureInitialized();

setUp(() async {
  await GlobalConfiguration().loadFromAsset("app_settings");
});
```

- Initializes integration test framework
- Loads configuration from `app_settings.json`

#### 2. App Initialization

```dart
RestClient restClient = RestClient(await buildDioClient());
await CommonTest.startTestApp(
  tester,
  generateRoute,                    // Route generator from main.dart
  testMenuOptions,                  // Menu structure for testing
  UserCompanyLocalizations.localizationsDelegates,
  restClient: restClient,
  blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
  title: 'GrowERP user-lead test',
  clear: true,                      // Clear previous test data
);
```

**What happens:**
- Creates REST client for backend communication
- Launches app with test-specific configuration
- Initializes BLoC providers for state management
- Clears any existing test data

#### 3. Create Test Company

```dart
await CommonTest.createCompanyAndAdmin(tester);
```

**What happens:**
- Creates a new company
- Creates admin user
- Logs in as admin
- Returns to main menu

#### 4. Navigate to Leads

```dart
Future<void> selectLeads(WidgetTester tester) async {
  await UserTest.selectUsers(tester, '/users', 'UserListLead', '2');
}

await selectLeads(tester);
```

**What happens:**
- Navigates to main menu
- Selects "Users" option
- Switches to "Leads" tab (tab #2)
- Displays lead list view

#### 5. Add New Leads

```dart
await UserTest.addUsers(tester, leads.sublist(0, 3));
```

**What happens:**
- Takes first 3 leads from test data (`growerp_core/test_data.dart`)
- For each lead:
  - Taps "Add New User" button
  - Fills in first name, last name, email
  - Optionally adds address and payment method
  - Optionally assigns company
  - Taps "Update" to save
  - Extracts generated pseudoId from backend
  - Persists test data with pseudoId for future use

**Test Data Example:**
```dart
List<User> leads = [
  User(
    firstName: 'Lead',
    lastName: 'One',
    email: 'lead1XXX@example.com',  // XXX replaced with sequence number
    role: Role.lead,
  ),
  // ... more leads
];
```

#### 6. Verify Added Leads

```dart
await UserTest.checkUsers(tester);
```

**What happens:**
- Loads persisted test data
- For each lead:
  - Searches by first name
  - Opens detail dialog
  - Verifies all fields match expected values
  - Checks address and payment method if present
  - Closes dialog

#### 7. Update Leads

```dart
await UserTest.updateUsers(tester, leads.sublist(3, 6));
```

**What happens:**
- Takes leads 3-6 from test data (updated versions)
- Copies pseudoId from previously saved test data
- For each lead:
  - Searches by pseudoId
  - Updates form fields with new values
  - Saves changes
  - Persists updated test data

#### 8. Verify Updates

```dart
await UserTest.checkUsers(tester);
```

**What happens:**
- Repeats verification process with updated data

#### 9. Delete Lead

```dart
await UserTest.deleteUsers(tester);
```

**What happens:**
- Counts total users in list
- Taps delete button on last user
- Verifies user count decreased by 1
- Updates persisted test data

#### 10. Cleanup

```dart
await CommonTest.logout(tester);
```

**What happens:**
- Logs out current user
- Returns to login screen

---

## Writing Integration Tests

### Pattern: Complete Test Workflow

Follow this pattern for new integration tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('Test description', (tester) async {
    // 1. Initialize app
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      generateRoute,
      testMenuOptions,
      YourPackageLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getYourBlocProviders(restClient, 'AppAdmin'),
      title: 'Your test title',
      clear: true,
    );

    // 2. Create company and admin
    await CommonTest.createCompanyAndAdmin(tester);

    // 3. Navigate to your feature
    await CommonTest.selectOption(tester, 'menuOption', 'FormName', 'tabNumber');

    // 4. Test CRUD operations
    await YourTest.addItems(tester, testData.sublist(0, 3));
    await YourTest.checkItems(tester);
    await YourTest.updateItems(tester, testData.sublist(3, 6));
    await YourTest.checkItems(tester);
    await YourTest.deleteItems(tester);

    // 5. Cleanup
    await CommonTest.logout(tester);
  });
}
```

### Creating Domain Test Helpers

Create reusable test methods in `lib/src/your_domain/integration_test/`:

```dart
class YourTest {
  static Future<void> addItems(
    WidgetTester tester,
    List<YourModel> items,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(yourItems: items));
    
    for (YourModel item in items) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.enterText(tester, 'name', item.name);
      // ... fill other fields
      await CommonTest.tapByKey(tester, 'update');
      
      // Extract generated ID
      String id = CommonTest.getTextField('topHeader').split('#')[1];
      item = item.copyWith(pseudoId: id);
    }
    
    await PersistFunctions.persistTest(test.copyWith(yourItems: items));
  }

  static Future<void> checkItems(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (YourModel item in test.yourItems) {
      await CommonTest.doNewSearch(tester, searchString: item.name);
      expect(CommonTest.getTextFormField('name'), equals(item.name));
      // ... check other fields
      await CommonTest.tapByKey(tester, 'cancel');
    }
  }

  static Future<void> updateItems(
    WidgetTester tester,
    List<YourModel> newItems,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    
    // Copy pseudoIds from old data
    for (int x = 0; x < newItems.length; x++) {
      newItems[x] = newItems[x].copyWith(pseudoId: old.yourItems[x].pseudoId);
    }
    
    await PersistFunctions.persistTest(old.copyWith(yourItems: newItems));
    
    for (YourModel item in newItems) {
      await CommonTest.doNewSearch(tester, searchString: item.pseudoId!);
      await CommonTest.enterText(tester, 'name', item.name);
      // ... update other fields
      await CommonTest.tapByKey(tester, 'update');
    }
  }

  static Future<void> deleteItems(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.yourItems.length;
    
    expect(find.byKey(const Key('itemWidget')), findsNWidgets(count));
    await CommonTest.tapByKey(tester, 'delete${count - 1}');
    expect(find.byKey(const Key('itemWidget')), findsNWidgets(count - 1));
    
    PersistFunctions.persistTest(
      test.copyWith(yourItems: test.yourItems.sublist(0, count - 1)),
    );
  }
}
```

---

## Test Data Management

### Test Data Location

Test data is centralized in `growerp_core/lib/test_data.dart`:

```dart
List<User> leads = [
  User(
    firstName: 'Lead',
    lastName: 'One',
    email: 'lead1XXX@example.com',
    telephoneNr: '+1234567890',
    role: Role.lead,
  ),
  User(
    firstName: 'Lead',
    lastName: 'Two',
    email: 'lead2XXX@example.com',
    company: Company(
      name: 'Lead Company Two',
      role: Role.customer,
    ),
    role: Role.lead,
  ),
  // Updated versions for update tests
  User(
    firstName: 'Updated Lead',
    lastName: 'One Modified',
    email: 'lead1XXX@example.com',  // Same pattern, different values
    role: Role.lead,
  ),
];
```

### Data Pattern: XXX Placeholder

The `XXX` placeholder in email/URL fields is replaced with sequence numbers:

```dart
user = user.copyWith(
  email: user.email!.replaceFirst('XXX', '${seq++}'),
);
```

**Purpose**: Ensures unique emails across test runs (backend often requires unique emails).

### SaveTest Model

Test data is persisted using the `SaveTest` model:

```dart
class SaveTest {
  final List<User> users;
  final List<Product> products;
  final List<Category> categories;
  final int sequence;  // For unique email generation
  
  SaveTest({
    this.users = const [],
    this.products = const [],
    this.categories = const [],
    this.sequence = 0,
  });
  
  SaveTest copyWith({
    List<User>? users,
    List<Product>? products,
    int? sequence,
  }) { /* ... */ }
}
```

### Persistence Methods

```dart
// Save test data
await PersistFunctions.persistTest(test);

// Load latest test data
SaveTest test = await PersistFunctions.getTest();

// Load backup (for comparison in check methods)
SaveTest test = await PersistFunctions.getTest(backup: false);
```

---

## Running Tests

### Run All Integration Tests

From the `flutter/` directory:

```bash
melos test
```

**What happens:**
- Runs integration tests for all packages in dependency order
- Defined in `melos.yaml`

### Run Tests for Specific Package

```bash
cd flutter/packages/growerp_user_company/example
flutter test integration_test/user_lead_test.dart
```

### Run Tests with Docker (Headless)

For CI/CD environments:

```bash
cd flutter
./build_run_all_tests.sh
```

**What happens:**
- Starts Docker containers (backend, emulator)
- Runs all integration tests in headless mode
- Captures results

### Test Execution Order

Tests run in dependency order as defined in `melos.yaml`:

1. `growerp_models` (no integration tests, just unit tests)
2. `growerp_core` (core functionality tests)
3. Domain packages: `growerp_user_company`, `growerp_catalog`, etc.
4. Applications: `admin`, `hotel`, etc.

---

## Test Helper Classes

### CommonTest Key Methods

#### App Lifecycle

```dart
// Start app with test configuration
await CommonTest.startTestApp(
  tester,
  generateRoute,
  menuOptions,
  localizationsDelegates,
  restClient: restClient,
  blocProviders: blocProviders,
  title: 'Test title',
  clear: true,  // Clear previous test data
);

// Create initial company and admin
await CommonTest.createCompanyAndAdmin(tester);

// Logout
await CommonTest.logout(tester);
```

#### Navigation

```dart
// Navigate to menu option
await CommonTest.selectOption(
  tester,
  'dbCrm',           // Main menu option
  'UserListLead',    // Target form name
  '2',               // Tab number
);

// Go to main menu
await CommonTest.gotoMainMenu(tester);
```

#### User Interaction

```dart
// Tap widget by key
await CommonTest.tapByKey(tester, 'addNewUser');

// Enter text in form field
await CommonTest.enterText(tester, 'firstName', 'John');

// Select dropdown value
await CommonTest.enterDropDown(tester, 'userGroup', 'Admin');

// Toggle checkbox
await CommonTest.tapByKey(tester, 'loginDisabled');

// Search in list
await CommonTest.doNewSearch(tester, searchString: 'John');
```

#### Scrolling

```dart
// Scroll until widget is visible
await CommonTest.dragUntil(
  tester,
  key: 'loginName',
  listViewName: 'userDialogListView',
);

// Simple scroll down
await CommonTest.drag(tester, listViewName: 'userDialogListView');
```

#### Data Retrieval

```dart
// Get text from Text widget
String name = CommonTest.getTextField('firstName');

// Get value from TextFormField
String email = CommonTest.getTextFormField('userEmail');

// Get dropdown value
String role = CommonTest.getDropdown('userGroup');

// Get checkbox state
bool disabled = CommonTest.getCheckbox('loginDisabled');

// Check if widget exists
bool exists = await CommonTest.doesExistKey(tester, 'newCompany');
```

#### Timing

```dart
// Wait for async operations
await CommonTest.waitForSnackbarToGo(tester);

// Tap with delay
await CommonTest.tapByKey(
  tester,
  'update',
  seconds: CommonTest.waitTime,  // Default: 1 second
);
```

### UserTest Methods

```dart
// Select user type
await UserTest.selectLeads(tester);
await UserTest.selectEmployees(tester);
await UserTest.selectCustomers(tester);
await UserTest.selectSuppliers(tester);

// CRUD operations
await UserTest.addUsers(tester, users);
await UserTest.updateUsers(tester, updatedUsers);
await UserTest.deleteUsers(tester);
await UserTest.checkUsers(tester);

// Advanced: Fill user form (handles complex logic)
await UserTest.enterUserData(tester, companyUser: false);
```

---

## Best Practices

### 1. Use Test Helpers

❌ **Don't:**
```dart
await tester.tap(find.byKey(const Key('addNewUser')));
await tester.pumpAndSettle();
```

✅ **Do:**
```dart
await CommonTest.tapByKey(tester, 'addNewUser');
```

**Why:** Test helpers handle timing, scrolling, and error handling automatically.

### 2. Persist Test Data

❌ **Don't:**
```dart
List<String> userIds = [];
// Store IDs in local variables
```

✅ **Do:**
```dart
SaveTest test = await PersistFunctions.getTest();
test = test.copyWith(users: usersWithIds);
await PersistFunctions.persistTest(test);
```

**Why:** Enables incremental testing and data reuse across tests.

### 3. Use Descriptive Keys

❌ **Don't:**
```dart
Key('button1')
```

✅ **Do:**
```dart
Key('addNewUser')
Key('updateUserButton')
Key('delete${index}')
```

**Why:** Makes tests readable and maintainable.

### 4. Test in Dependency Order

Organize tests to follow app flow:

1. Setup (create company, admin)
2. Add entities
3. Verify additions
4. Update entities
5. Verify updates
6. Delete entities
7. Cleanup (logout)

### 5. Use Sublist for Test Data

✅ **Good:**
```dart
await UserTest.addUsers(tester, leads.sublist(0, 3));  // First 3 for add
await UserTest.updateUsers(tester, leads.sublist(3, 6)); // Next 3 for update
```

**Why:** 
- Separates add vs. update test data
- Same test data can have "before" and "after" versions

### 6. Handle Async Operations

Always wait for async operations to complete:

```dart
await CommonTest.tapByKey(tester, 'update', seconds: CommonTest.waitTime);
await CommonTest.waitForSnackbarToGo(tester);
```

### 7. Clear Test Data

Start tests with clean state:

```dart
await CommonTest.startTestApp(
  tester,
  // ...
  clear: true,  // Clears previous test data
);
```

### 8. Scroll Before Interaction

If widget might be off-screen:

```dart
await CommonTest.dragUntil(
  tester,
  key: 'paymentMethodLabel',
  listViewName: 'userDialogListView',
);
await CommonTest.tapByKey(tester, 'paymentMethodLabel');
```

### 9. Test Both Success and Failure Paths

```dart
// Test successful creation
await UserTest.addUsers(tester, validUsers);
await UserTest.checkUsers(tester);

// Test validation errors
await UserTest.addUsers(tester, invalidUsers);
expect(find.text('Email is required'), findsOneWidget);
```

### 10. Use Semantic Test Names

```dart
testWidgets('GrowERP user lead test - CRUD operations', (tester) async {
  // ...
});

testWidgets('GrowERP product catalog - category assignment', (tester) async {
  // ...
});
```

---

## Troubleshooting

### Test Times Out

**Symptom:** Test hangs or times out during widget interaction.

**Solutions:**
- Increase wait time: `await CommonTest.tapByKey(tester, 'key', seconds: 5)`
- Check for infinite loading states in BLoCs
- Verify backend is responding

### Widget Not Found

**Symptom:** `expect(find.byKey(Key('widget')), findsOneWidget)` fails.

**Solutions:**
- Use `skipOffstage: false` if widget might be off-screen: `find.byKey(Key('widget'), skipOffstage: false)`
- Scroll to widget first: `await CommonTest.dragUntil(tester, key: 'widget')`
- Check widget key in source code

### Data Not Persisting

**Symptom:** Test fails because previous test data is not available.

**Solutions:**
- Ensure `PersistFunctions.persistTest()` is called after creating/updating data
- Check `SaveTest` model has correct fields
- Verify test runs in correct order (check `melos.yaml`)

### Email Already Exists Error

**Symptom:** Backend rejects user creation with "email already exists".

**Solutions:**
- Use `XXX` placeholder in test data emails
- Increment sequence number: `email: 'user${seq++}@example.com'`
- Clear test data with `clear: true` in `startTestApp()`

### Form Validation Errors

**Symptom:** Required field errors even though data is entered.

**Solutions:**
- Wait for async validation: `await tester.pumpAndSettle()`
- Check field names match keys in UI
- Scroll to ensure field is visible before entering text

### Tests Pass Individually but Fail When Run Together

**Symptom:** Tests work in isolation but fail when run as a suite.

**Solutions:**
- Clear state between tests with `clear: true`
- Use unique test data for each test
- Reset persisted data in `setUp()` if needed

### Backend Connection Errors

**Symptom:** `DioError` or connection timeout.

**Solutions:**
- Verify backend is running (Moqui server)
- Check `app_settings.json` has correct backend URL
- Ensure Docker containers are running (if using Docker tests)

---

## Advanced Topics

### Testing Complex Workflows

For multi-step workflows (e.g., create order → approve → invoice):

```dart
testWidgets('Order to invoice workflow', (tester) async {
  // 1. Setup
  await CommonTest.startTestApp(/* ... */);
  await CommonTest.createCompanyAndAdmin(tester);
  
  // 2. Create customer
  await UserTest.selectCustomers(tester);
  await UserTest.addUsers(tester, customers.sublist(0, 1));
  
  // 3. Create products
  await CommonTest.selectOption(tester, 'dbCatalog', 'ProductList', '1');
  await ProductTest.addProducts(tester, products.sublist(0, 2));
  
  // 4. Create sales order
  await CommonTest.selectOption(tester, 'dbOrders', 'SalesOrderList', '1');
  await OrderTest.addOrders(tester, salesOrders.sublist(0, 1));
  
  // 5. Approve order
  await OrderTest.approveOrder(tester);
  
  // 6. Create invoice
  await OrderTest.createInvoiceFromOrder(tester);
  
  // 7. Verify invoice
  await InvoiceTest.checkInvoices(tester);
  
  // 8. Cleanup
  await CommonTest.logout(tester);
});
```

### Testing Real-Time Features (WebSocket)

For features with real-time updates (e.g., chat):

```dart
testWidgets('Chat real-time messages', (tester) async {
  // Setup two users
  await CommonTest.startTestApp(/* ... */);
  await CommonTest.createCompanyAndAdmin(tester);
  
  // User 1 sends message
  await ChatTest.sendMessage(tester, 'Hello from user 1');
  
  // Wait for WebSocket update
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // User 2 receives message
  expect(find.text('Hello from user 1'), findsOneWidget);
  
  await CommonTest.logout(tester);
});
```

### Debugging Tests

Enable verbose logging:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() async {
    // Enable debug logging
    debugPrint('===== Starting test =====');
    await GlobalConfiguration().loadFromAsset("app_settings");
  });
  
  testWidgets('Test with logging', (tester) async {
    debugPrint('Step 1: Initialize app');
    await CommonTest.startTestApp(/* ... */);
    
    debugPrint('Step 2: Create company');
    await CommonTest.createCompanyAndAdmin(tester);
    
    debugPrint('Step 3: Test feature');
    // ...
  });
}
```

---

## Related Documentation

- **[Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)** - Creating new Flutter packages
- **[Backend Components Development Guide](./Backend_Components_Development_Guide.md)** - Moqui backend development
- **[GrowERP Design Patterns](./GrowERP_Design_Patterns.md)** - Coding patterns and conventions
- **[GrowERP Code Templates](./GrowERP_Code_Templates.md)** - Code generation templates

---

## Summary

GrowERP's integration testing framework provides:

✅ **Reusable test helpers** - `CommonTest`, `UserTest`, `ProductTest`, etc.  
✅ **Data persistence** - `PersistFunctions` for incremental testing  
✅ **Standardized patterns** - Consistent test structure across packages  
✅ **Comprehensive coverage** - 132+ integration tests across all packages  
✅ **CI/CD ready** - Headless test execution with Docker  

**Key Principles:**
1. Use domain test helpers for reusable CRUD operations
2. Persist test data for incremental testing
3. Follow setup → add → check → update → check → delete → cleanup pattern
4. Run tests in dependency order
5. Clear state between test runs

---

**Last Updated:** November 11, 2025  
**Maintained by:** GrowERP Community  
**Status:** ✅ PRODUCTION-READY

For questions or improvements to this documentation, please create an issue or submit a pull request.
