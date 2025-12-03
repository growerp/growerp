# GrowERP Assessment Integration Tests

This directory contains integration tests for the `growerp_assessment` package, following the patterns documented in [docs/Integration_Test_Guide.md](../../../../../docs/Integration_Test_Guide.md).

## Test Files

### 1. `landing_page_test.dart`
Tests the complete CRUD workflow for landing pages.

**Test Flow:**
1. Create company and admin user
2. Navigate to Landing Pages menu
3. Add 3 new landing pages
4. Verify all landing pages were created correctly
5. Update all 3 landing pages
6. Verify updates were applied
7. Delete one landing page
8. Logout

**Test Duration:** ~45 seconds

**Key Features Tested:**
- Landing page creation with various hook types (results, frustration, custom)
- Landing page editing and updates
- CTA action types (assessment, url)
- Privacy policy URL configuration
- Status management (DRAFT, ACTIVE, INACTIVE)

### 2. `assessment_test.dart`
Tests the complete CRUD workflow for assessments.

**Test Flow:**
1. Create company and admin user
2. Navigate to Assessments menu
3. Add 3 new assessments
4. Verify all assessments were created correctly
5. Update all 3 assessments
6. Verify updates were applied
7. Delete one assessment
8. Logout

**Test Duration:** ~40 seconds

**Key Features Tested:**
- Assessment creation with name and description
- Assessment editing and updates
- Status management (ACTIVE, INACTIVE, DRAFT)
- Assessment metadata (created date, modified date)

### 3. `take_assessment_test.dart`
Tests the assessment-taking user flow, including edge cases.

**Test Scenarios:**

#### Scenario 1: Normal Flow
1. Create company and admin user
2. Create a landing page
3. Create an assessment
4. Navigate to Take Assessment menu
5. Verify assessment list is displayed
6. Select an assessment
7. Verify assessment flow screen loads
8. Logout

**Test Duration:** ~50 seconds

#### Scenario 2: Empty State
1. Create company and admin user
2. Navigate to Take Assessment menu (without creating assessments)
3. Verify empty state message is displayed
4. Logout

**Test Duration:** ~20 seconds

**Key Features Tested:**
- Assessment list display
- Assessment selection and navigation
- Empty state handling
- Assessment flow screen initialization
- User-friendly messaging

## Running the Tests

### Run All Tests
```bash
cd flutter/packages/growerp_assessment/example
flutter test integration_test/
```

### Run Individual Tests
```bash
# Landing page test
flutter test integration_test/landing_page_test.dart

# Assessment test
flutter test integration_test/assessment_test.dart

# Take assessment test
flutter test integration_test/take_assessment_test.dart
```

### Run with Melos (from flutter/ directory)
```bash
cd flutter
melos test --scope="marketing_example"
```

### Run All Package Tests (from flutter/ directory)
```bash
cd flutter
melos test
```

## Test Data

Test data is defined in `growerp_assessment/lib/src/test_data.dart`:

- **landingPages**: 3 landing pages for add tests
- **updatedLandingPages**: 3 updated landing pages for update tests
- **assessments**: 3 assessments for add tests
- **updatedAssessments**: 3 updated assessments for update tests

All test data follows the GrowERP test data pattern with realistic scenarios.

## Test Helpers

These tests use reusable test helper classes:

### From `growerp_core`:
- **CommonTest**: Core UI interaction methods (tap, scroll, enter text, etc.)
- **PersistFunctions**: Test data persistence between runs

### From `growerp_assessment`:
- **LandingPageTest**: Landing page CRUD operations
  - `selectLandingPages()`: Navigate to landing pages menu
  - `addLandingPages()`: Create new landing pages
  - `updateLandingPages()`: Update existing landing pages
  - `deleteLandingPages()`: Delete landing pages
  - `checkLandingPages()`: Verify landing page data

- **AssessmentTest**: Assessment CRUD operations
  - `selectAssessments()`: Navigate to assessments menu
  - `addAssessments()`: Create new assessments
  - `updateAssessments()`: Update existing assessments
  - `deleteAssessments()`: Delete assessments
  - `checkAssessments()`: Verify assessment data

## Best Practices

These tests follow the integration test patterns documented in `docs/Integration_Test_Guide.md`:

✅ Use test helpers for reusable operations  
✅ Persist test data for incremental testing  
✅ Follow setup → add → check → update → check → delete → cleanup pattern  
✅ Clear state between test runs with `clear: true`  
✅ Use descriptive test names  
✅ Wait for async operations with `pumpAndSettle()`  
✅ Verify both success and edge cases  

## Troubleshooting

### Test Times Out
- Check backend is running and responding
- Increase wait time in `CommonTest.tapByKey()`
- Verify network connectivity

### Widget Not Found
- Ensure widget keys match UI implementation
- Check if widget is off-screen (use `skipOffstage: false`)
- Scroll to widget before interaction

### Data Not Persisting
- Verify `PersistFunctions.persistTest()` is called after operations
- Check `SaveTest` model has correct fields
- Run with `clear: true` to reset state

### Backend Connection Errors
- Verify Moqui backend is running (port 8080)
- Check `assets/cfg/app_settings.json` has correct URL
- Ensure test data doesn't conflict with existing data

## CI/CD Integration

These tests can be run in headless mode using Docker:

```bash
cd flutter
./build_run_all_tests.sh
```

This script:
1. Starts Docker containers (backend, emulator)
2. Runs all integration tests in dependency order
3. Captures results and logs
4. Tears down containers

## Documentation

For more information on the GrowERP integration testing framework, see:

- **[Integration Test Guide](../../../../../docs/Integration_Test_Guide.md)** - Complete framework documentation
- **[Building Blocks Development Guide](../../../../../docs/Building_Blocks_Development_Guide.md)** - Package development patterns
- **[GrowERP Design Patterns](../../../../../docs/GrowERP_Design_Patterns.md)** - Coding conventions

---

**Last Updated:** November 13, 2025  
**Package:** growerp_assessment v1.9.0  
**Test Coverage:** Landing Pages, Assessments, Take Assessment Flow
