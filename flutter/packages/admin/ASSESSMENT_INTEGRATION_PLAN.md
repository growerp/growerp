# Assessment Module Integration Plan for Admin App

## Overview
This document outlines the step-by-step process to integrate the `growerp_assessment` module into the GrowERP admin application.

## Phase 2: Admin App Integration

### Step 1: Update Dependencies ✓ Need to implement
**File**: `pubspec.yaml`

Add the assessment module dependency:
```yaml
dependencies:
  growerp_assessment: ^1.9.0
```

### Step 2: Update Main BLoC Providers
**File**: `lib/main.dart`

1. Import the assessment module:
```dart
import 'package:growerp_assessment/growerp_assessment.dart';
```

2. Add assessment BLoC provider to `getAdminBlocProviders()`:
```dart
List<BlocProvider> getAdminBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [
    ...getInventoryBlocProviders(restClient, classificationId),
    ...getUserCompanyBlocProviders(restClient, classificationId),
    ...getCatalogBlocProviders(restClient, classificationId),
    ...getOrderAccountingBlocProviders(restClient, classificationId),
    ...getMarketingBlocProviders(restClient),
    ...getWebsiteBlocProviders(restClient),
    ...getAssessmentBlocProviders(restClient), // ADD THIS LINE
  ];
}
```

3. Add assessment localizations delegate:
```dart
List<LocalizationsDelegate> delegates = [
  UserCompanyLocalizations.delegate,
  CatalogLocalizations.delegate,
  InventoryLocalizations.delegate,
  OrderAccountingLocalizations.delegate,
  WebsiteLocalizations.delegate,
  MarketingLocalizations.delegate,
  InventoryLocalizations.delegate,
  ActivityLocalizations.delegate,
  AssessmentLocalizations.delegate, // ADD THIS LINE
];
```

### Step 3: Update Menu Options
**File**: `lib/menu_options.dart`

1. Import assessment module:
```dart
import 'package:growerp_assessment/growerp_assessment.dart';
```

2. Add assessment menu item in `getMenuOptions()`:
```dart
MenuOption(
  image: 'packages/growerp_core/images/surveyGrey.png',
  selectedImage: 'packages/growerp_core/images/survey.png',
  title: 'Assessments',
  route: '/assessments',
  userGroups: [UserGroup.admin, UserGroup.employee],
  tabItems: [
    TabItem(
      form: const AssessmentListPage(),
      label: 'Assessments',
      icon: const Icon(Icons.assignment),
    ),
    TabItem(
      form: const AssessmentResultsPage(),
      label: 'Results',
      icon: const Icon(Icons.description),
    ),
  ],
),
```

### Step 4: Update Router
**File**: `lib/router.dart`

Add route handler for assessment module:
```dart
case '/assessments':
  return MaterialPageRoute(
    builder: (context) => const AssessmentListPage(),
  );
case '/assessments/detail':
  return MaterialPageRoute(
    builder: (context) => AssessmentDetailPage(
      assessmentId: settings.arguments as String,
    ),
  );
case '/assessments/flow':
  return MaterialPageRoute(
    builder: (context) => AssessmentFlowScreen(
      assessmentId: settings.arguments as String,
      onComplete: () => Navigator.pop(context),
    ),
  );
```

### Step 5: Create Assessment List Page
**File**: `lib/views/assessment_list_page.dart` (NEW)

Create a list page wrapper that:
- Displays all assessments
- Shows creation, edit, and delete options
- Links to results
- Shows status indicators

### Step 6: Create Assessment Results Page
**File**: `lib/views/assessment_results_page.dart` (NEW)

Create a results page wrapper that:
- Shows assessment submissions
- Displays scores and lead statuses
- Provides filtering options
- Allows export/analysis

### Step 7: Update Assets (Optional)
Add assessment-related icons to `pubspec.yaml`:
```yaml
assets:
  - packages/growerp_core/images/surveyGrey.png
  - packages/growerp_core/images/survey.png
```

## Testing Checklist

After integration, verify:

- [ ] Admin app builds without errors
- [ ] Assessment menu item appears in navigation
- [ ] Can navigate to assessment list page
- [ ] Can create new assessment
- [ ] Can view assessment details
- [ ] Can navigate to assessment flow (Step 1: Lead capture)
- [ ] Form validation works correctly
- [ ] Can proceed through all 3 steps
- [ ] Results display correctly with score/status
- [ ] Can view assessment results
- [ ] No console errors or warnings
- [ ] Responsive layout works on mobile/tablet/desktop

## Integration Points Summary

### 1. Dependency Management
- Assessment module added to pubspec.yaml
- All dependencies resolved correctly

### 2. State Management
- AssessmentBloc provided via getAssessmentBlocProviders()
- Assessment repository initialized with RestClient
- BLoC accessible throughout app

### 3. Navigation
- Routes configured for all assessment screens
- Menu option integrated into admin navigation
- Tab items for list and results views

### 4. Localization
- Assessment localizations delegate added
- Menu labels and titles localized

### 5. UI/UX
- Consistent Material Design 3
- Responsive layouts
- Integration with existing admin styling

## Files to Modify

1. ✓ `pubspec.yaml` - Add dependency
2. ✓ `lib/main.dart` - Add BLoC provider and localizations
3. ✓ `lib/menu_options.dart` - Add menu item
4. ✓ `lib/router.dart` - Add routes
5. ⚪ `lib/views/assessment_list_page.dart` - Create (optional wrapper)
6. ⚪ `lib/views/assessment_results_page.dart` - Create (optional wrapper)

## Rollout Plan

### Phase 2a: Dependencies & Setup (30 min)
- Update pubspec.yaml
- Update main.dart BLoC providers
- Update main.dart localizations
- Run flutter pub get
- Verify builds

### Phase 2b: Navigation & Routing (20 min)
- Update menu_options.dart
- Update router.dart
- Test menu navigation
- Test route transitions

### Phase 2c: Testing & Polish (30 min)
- Run through testing checklist
- Fix any UI/UX issues
- Performance optimization
- Documentation updates

## Success Criteria

✅ Admin app builds without errors
✅ Assessment module accessible from main menu
✅ All 3-step assessment flow works
✅ Results display correctly
✅ No breaking changes to existing admin functionality
✅ All tests pass
✅ Responsive design verified

## Rollback Plan

If issues occur during integration:
1. Remove growerp_assessment dependency from pubspec.yaml
2. Revert main.dart BLoC provider changes
3. Revert menu_options.dart changes
4. Revert router.dart changes
5. Run flutter pub get && flutter clean && flutter pub get
6. Rebuild application

---

**Status**: Ready for implementation
**Last Updated**: October 24, 2025
**Next Step**: Execute Phase 2a (Dependencies & Setup)
