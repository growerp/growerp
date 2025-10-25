# Assessment Screens Documentation

## Overview

The Assessment Screens module provides a complete 3-step assessment user interface for GrowERP. Users move through lead capture, question answering, and results viewing in a guided flow with progress tracking and validation.

## Architecture

### Screen Hierarchy

```
AssessmentFlowScreen (Container)
├── LeadCaptureScreen (Step 1)
├── AssessmentQuestionsScreen (Step 2)
└── AssessmentResultsScreen (Step 3)
```

### State Management

- **AssessmentFlowScreen**: Manages state across all three screens, stores respondent data and answers
- **Individual Screens**: Handle their own UI logic and validation
- **BLoC Integration**: Screens communicate with AssessmentBloc for data operations

## Screens

### 1. LeadCaptureScreen

**Location**: `lib/src/screens/lead_capture_screen.dart`

**Purpose**: Collects respondent information before assessment begins

**Features**:
- Form validation for required fields (name, email)
- Optional fields (company, phone)
- Email format validation
- Progress indicator showing Step 1 of 3
- Responsive design (mobile/tablet/desktop)
- Material Design styling

**Props**:
- `assessmentId` (String): ID of the assessment
- `onRespondentDataCollected` (Function): Callback with collected data
- `onNext` (VoidCallback): Callback to move to next step

**Form Fields**:
```dart
Full Name * (required, min 2 chars)
Email Address * (required, valid email format)
Company Name (optional)
Phone Number (optional)
```

**Validation Rules**:
- Name: required, minimum 2 characters
- Email: required, valid RFC format
- Company: optional
- Phone: optional

### 2. AssessmentQuestionsScreen

**Location**: `lib/src/screens/assessment_questions_screen.dart`

**Purpose**: Display assessment questions and collect answers

**Features**:
- Paginated question display (one per page)
- Radio button selection for options
- Answer tracking and state management
- Previous/Next navigation with proper boundary handling
- Progress indicator showing current question count
- Loading states for question data
- Error handling with user feedback

**Props**:
- `assessmentId` (String): ID of the assessment
- `onAnswersCollected` (Function): Callback with collected answers
- `onNext` (VoidCallback): Callback to submit and move to results
- `onPrevious` (VoidCallback): Callback to go back to lead capture

**Features**:
- Question pagination via PageView
- Answer persistence across page transitions
- Option cards with selection visual feedback
- Navigation validation

### 3. AssessmentResultsScreen

**Location**: `lib/src/screens/assessment_results_screen.dart`

**Purpose**: Display assessment results with score and lead status

**Features**:
- Score display with visual progress bar
- Color-coded score ranges (green 80+, orange 60-79, red <60)
- Lead status with icon and color coding
- Summary card with respondent info and completion time
- Export/Share functionality placeholder
- Complete button to finalize assessment

**Props**:
- `assessmentId` (String): ID of the assessment
- `respondentName` (String): Name of respondent
- `onComplete` (VoidCallback): Callback when assessment is complete

**Score Color Mapping**:
- 80-100: Green (Qualified)
- 60-79: Orange (Interested)
- 0-59: Red (Not Qualified)

**Lead Status Icons**:
- QUALIFIED: Thumb up (green)
- INTERESTED: Info icon (orange)
- NOT_QUALIFIED: Thumb down (red)
- UNKNOWN: Help icon (grey)

### 4. AssessmentFlowScreen

**Location**: `lib/src/screens/assessment_flow_screen.dart`

**Purpose**: Container that orchestrates the 3-step flow

**Features**:
- PageView-based navigation between screens
- State preservation across screen transitions
- Respondent data storage
- Answer collection
- Back button handling (navigates to previous step)
- Integration with AssessmentBloc for submission

**Props**:
- `assessmentId` (String): ID of the assessment
- `onComplete` (VoidCallback): Callback when entire flow is complete

**Internal State**:
- `_currentStep`: Current screen index (0-2)
- `_respondentName`, `_respondentEmail`, `_respondentCompany`, `_respondentPhone`: Collected in Step 1
- `_answers`: Map of question ID to selected option ID

## Usage Example

### Basic Integration

```dart
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyAssessmentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AssessmentBloc(
        repository: AssessmentRepository(
          apiClient: AssessmentApiClient(dio),
          logger: logger,
        ),
      ),
      child: AssessmentFlowScreen(
        assessmentId: 'assessment-123',
        onComplete: () {
          // Handle completion
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

### Individual Screen Usage

```dart
// Use individual screens separately if needed
LeadCaptureScreen(
  assessmentId: 'assessment-123',
  onRespondentDataCollected: ({
    required String name,
    required String email,
    required String company,
    required String phone,
  }) {
    // Handle data
  },
  onNext: () {
    // Move to next screen
  },
)
```

## Design Patterns

### Progress Tracking

All screens display a visual progress indicator with step numbers and labels:
```
[1: Your Info] ---- [2: Questions] ---- [3: Results]
```

### Form Validation

- LeadCaptureScreen uses Flutter's Form widget with validation
- Real-time validation on field blur
- Error messages displayed below fields
- Submit button disabled until form is valid

### State Management

- Parent AssessmentFlowScreen holds shared state
- Individual screens communicate via callbacks
- BLoC handles async operations (API calls, submissions)

### Responsive Design

- Mobile: Single column layout, larger touch targets, padding adjustments
- Tablet/Desktop: Expanded layout with more whitespace

## Testing

### Widget Tests

Located in `test/widgets/`:
- `lead_capture_screen_test.dart`: 9 tests covering form validation, submission, etc.
- `assessment_flow_screen_test.dart`: 6 tests covering navigation and state management

### Test Coverage Areas

- Form field rendering and validation
- Callback invocation with correct data
- Navigation between screens
- Error handling and user feedback
- Responsive layout behavior
- Page transitions and state preservation

### Running Tests

```bash
# Run all widget tests
flutter test test/widgets/

# Run specific test
flutter test test/widgets/lead_capture_screen_test.dart
```

## Styling and Theming

### Material Design

All screens use Material 3 design principles:
- AppBar with elevation
- Card-based layouts
- Rounded corners (8-16px border radius)
- Standard button styles (ElevatedButton, OutlinedButton)
- Color consistency with theme

### Responsive Breakpoints

```dart
const mobileBreakpoint = 600;
final isMobile = MediaQuery.of(context).size.width < mobileBreakpoint;
```

### Color Scheme

- Primary: Blue (progress indicators, active elements)
- Success: Green (qualified status, progress)
- Warning: Orange (interested status)
- Error: Red (not qualified status)
- Neutral: Grey (disabled, secondary text)

## Error Handling

### User-Friendly Messages

- Network errors: "Connection failed. Please try again."
- Validation errors: Specific field-level messages
- API errors: User-friendly descriptions
- BLoC errors: Snackbar notifications

### Error States

- Loading states with CircularProgressIndicator
- Empty states with helpful messages
- Error states with retry options

## Accessibility

Features implemented:
- Semantic labels for form fields
- Icon + text combinations for buttons
- Color not sole indicator of status
- Proper tab order in forms
- Touch target sizes >= 48x48dp

## Future Enhancements

- [ ] Export results to PDF
- [ ] Share results via email/messaging
- [ ] Save draft assessments
- [ ] Assessment history tracking
- [ ] Analytics dashboard
- [ ] Conditional questions (show/hide based on answers)
- [ ] Time-limited assessments
- [ ] Multi-language support
- [ ] Dark mode theming
- [ ] Offline assessment capabilities

## Related Files

- Models: `lib/src/models/` - Data structures
- BLoC: `lib/src/bloc/assessment_bloc.dart` - State management
- Repository: `lib/src/repository/assessment_repository.dart` - Data access
- API Client: `lib/src/api/assessment_api_client.dart` - Backend communication

## Dependencies

- `flutter/material.dart` - UI framework
- `flutter_bloc/flutter_bloc.dart` - State management
- `growerp_assessment` models and BLoC

## Code Organization

```
lib/src/screens/
├── lead_capture_screen.dart         (125 lines, 1 widget)
├── assessment_questions_screen.dart (240 lines, 1 widget + helpers)
├── assessment_results_screen.dart   (210 lines, 1 widget + helpers)
├── assessment_flow_screen.dart      (120 lines, 1 widget)
└── screens.dart                      (export file)

test/widgets/
├── lead_capture_screen_test.dart     (185 lines, 9 tests)
└── assessment_flow_screen_test.dart  (95 lines, 6 tests)
```

## Performance Considerations

- PageView with fixed children (no lazy loading)
- Images optimized for screen size
- Minimal rebuilds via state management
- Form validation debounced
- API calls batched in submission

## Browser Compatibility (Web)

- Chrome/Edge: Fully supported
- Firefox: Fully supported
- Safari: Fully supported
- Mobile browsers: Responsive design

## Troubleshooting

### Screen not displaying
- Verify AssessmentBloc is provided in widget tree
- Check assessmentId is valid
- Ensure BLoC state listeners are set up

### Form validation not working
- Check TextFormField validator functions
- Ensure Form.validate() is called on submission
- Verify field controller lifecycle

### Navigation not working
- Check PageController state in AssessmentFlowScreen
- Verify callbacks are properly passed
- Check for navigation conflicts with Navigator

### Data not persisting
- Verify AssessmentFlowScreen state is maintained
- Check BLoC provides correct state after submission
- Ensure API client properly deserializes responses
