# GrowERP Assessment Package

Type-safe Flutter package for assessment and lead scoring functionality in GrowERP.

## Features

- **Assessment Management**: Create, update, and manage assessments
- **Question Management**: Add questions with multiple choice options
- **Scoring System**: Define score ranges and thresholds for lead categorization
- **Result Tracking**: Store and analyze assessment responses
- **Multi-tenant Support**: Full tenant isolation for all operations
- **Dual-ID Strategy**: Both system-wide and tenant-specific identifiers

## Models

### Core Models

- **Assessment**: Main survey/assessment definition
- **AssessmentQuestion**: Individual questions within an assessment
- **AssessmentQuestionOption**: Answer options for multiple choice questions
- **ScoringThreshold**: Score ranges that determine lead status
- **AssessmentResult**: Responses and scores from assessment submissions

### Data Structure

All models support:
- **Immutability**: `copyWith()` method for creating modified copies
- **JSON Serialization**: Automatic `fromJson()`/`toJson()` via `@JsonSerializable()`
- **Equality**: Proper `==` and `hashCode` implementation
- **Debugging**: Descriptive `toString()` methods

## Screens

### 3-Step Assessment Flow

The package includes complete UI screens for a guided assessment experience:

#### LeadCaptureScreen (Step 1)
- Collect respondent information (name, email, company, phone)
- Form validation with real-time feedback
- Progress indicator showing step 1 of 3

#### AssessmentQuestionsScreen (Step 2)
- Display questions one per page
- Multiple choice answer options
- Answer tracking and persistence
- Progress indication (question N of M)

#### AssessmentResultsScreen (Step 3)
- Display final score with color-coded status
- Lead status with visual indicators
- Summary of respondent information
- Export/share functionality

#### AssessmentFlowScreen (Container)
- Orchestrate flow between all 3 screens
- Manage state across transitions
- Handle back button navigation
- Integrate with BLoC for submission

### Usage

```dart
import 'package:growerp_assessment/growerp_assessment.dart';

BlocProvider(
  create: (context) => AssessmentBloc(repository: repo),
  child: AssessmentFlowScreen(
    assessmentId: 'assessment_123',
    onComplete: () {
      Navigator.pop(context);
    },
  ),
)
```

See [Screens Documentation](lib/src/screens/SCREENS_README.md) for detailed information.

## API Client

### AssessmentApiClient

Type-safe Retrofit client with endpoints for:

#### Assessment Operations
- `getAssessment()` - Retrieve single assessment
- `listAssessments()` - List assessments with pagination
- `createAssessment()` - Create new assessment
- `updateAssessment()` - Update existing assessment
- `deleteAssessment()` - Delete assessment
- `submitAssessment()` - Submit and score assessment

#### Question Management
- `createQuestion()` - Add question to assessment
- `updateQuestion()` - Modify question
- `deleteQuestion()` - Remove question
- `listQuestions()` - Get all questions for assessment

#### Option Management
- `createOption()` - Add answer option
- `updateOption()` - Modify option
- `deleteOption()` - Remove option
- `listOptions()` - Get all options for question

#### Scoring
- `getThresholds()` - Retrieve score thresholds
- `updateThresholds()` - Set/modify thresholds
- `calculateScore()` - Calculate score for answers

#### Results
- `listResults()` - Get assessment responses
- `getResult()` - Retrieve single response
- `deleteResult()` - Remove response

## Getting Started

### Installation

1. Add to `pubspec.yaml`:
```yaml
growerp_assessment: ^1.9.0
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
flutter pub run build_runner build
```

### Usage Example

```dart
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:dio/dio.dart';

// Initialize API client
final dio = Dio();
final apiClient = AssessmentApiClient(dio, baseUrl: 'https://api.growerp.com');

// Fetch assessment
final assessment = await apiClient.getAssessment('assessment_123');

// List questions
final questions = await apiClient.listQuestions(assessment.assessmentId);

// Submit assessment
final result = AssessmentResult(
  resultId: 'result_123',
  pseudoId: 'pseudo_result_123',
  assessmentId: assessment.assessmentId,
  ownerPartyId: 'company_id',
  score: 85.0,
  leadStatus: 'qualified',
  respondentName: 'John Doe',
  respondentEmail: 'john@example.com',
  answersData: jsonEncode(answers),
  createdDate: DateTime.now(),
);

final submitted = await apiClient.submitAssessment(
  assessment.assessmentId,
  result,
);
```

## Architecture

### Dual-ID Strategy

Each entity supports two types of identifiers:

- **entityId**: System-wide unique identifier used internally
- **pseudoId**: Tenant-unique identifier for external/API access

This allows:
- Public endpoints without authentication (using pseudoId)
- Secure internal operations (using entityId)
- Multi-tenant isolation with natural pseudo-IDs

### Multi-tenant Support

All models include `ownerPartyId` field for:
- Tenant data isolation
- Access control validation
- Multi-company operations

## Development

### Building

```bash
# Generate code (JSON serialization, Retrofit client)
flutter pub run build_runner build

# Watch mode for development
flutter pub run build_runner watch
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/models/assessment_test.dart
```

## Package Dependencies

- **growerp_models**: Core models and types
- **growerp_core**: Core functionality and BLoCs
- **json_serializable**: JSON code generation
- **retrofit**: Type-safe HTTP client generation
- **dio**: HTTP client
- **flutter_bloc**: State management
- **equatable**: Value equality helpers

## Dependencies Hierarchy

```
growerp_assessment
├── growerp_core
│   ├── growerp_models
│   └── [core dependencies]
├── growerp_models
└── [serialization & API packages]
```

## See Also

- [Backend API Reference](../../docs/ASSESSMENT_API_REFERENCE.md)
- [Implementation Sequence](../../docs/IMPLEMENTATION_SEQUENCE.md)
- [GrowERP Architecture Guide](../../docs/GrowERP_Extensibility_Guide.md)
