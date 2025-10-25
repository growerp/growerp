# GrowERP Assessment Package - Complete Developer Guide

**Package**: growerp_assessment  
**Version**: 1.9.0  
**Status**: Production Ready  
**Last Updated**: October 24, 2025

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Components](#components)
4. [Usage Examples](#usage-examples)
5. [API Reference](#api-reference)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Installation

1. **Add to pubspec.yaml**:
```yaml
dependencies:
  growerp_assessment: ^1.9.0
```

2. **Install dependencies**:
```bash
flutter pub get
flutter pub run build_runner build
```

3. **Initialize in your app**:
```dart
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:dio/dio.dart';

// Create DIO instance with authentication
final dio = Dio();
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    options.headers['Authorization'] = 'Bearer $authToken';
    return handler.next(options);
  },
));

// Create API client
final apiClient = AssessmentApiClient(dio, baseUrl: 'https://api.growerp.com');

// Create repository
final repository = AssessmentRepository(
  apiClient: apiClient,
  logger: Logger(),
);

// Create service
final service = AssessmentService(
  repository: repository,
  logger: Logger(),
);

// Create BLoC
final bloc = AssessmentBloc(
  repository: repository,
  logger: Logger(),
);
```

### Basic Usage

```dart
// Load an assessment
context.read<AssessmentBloc>().add(
  GetAssessmentEvent('assessment_123'),
);

// Listen to state changes
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentLoaded) {
      print('Assessment loaded: ${state.assessment.assessmentName}');
    } else if (state is AssessmentError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: // Your UI
);

// Build UI based on state
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is AssessmentLoading) {
      return const CircularProgressIndicator();
    } else if (state is AssessmentLoaded) {
      return AssessmentView(assessment: state.assessment);
    } else if (state is AssessmentError) {
      return ErrorView(message: state.message);
    }
    return const SizedBox.shrink();
  },
);
```

---

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────────┐
│           UI Layer (Widgets)             │
│    (Screens, Dialogs, Components)        │
└────────────────┬────────────────────────┘
                 │ BlocBuilder/BlocListener
┌────────────────▼────────────────────────┐
│        State Management (BLoC)           │
│  (Events → Handlers → States)            │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│       Business Logic (Service)           │
│  (Validation, Scoring, Analytics)        │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│         Data Access (Repository)         │
│  (API interaction, Error handling)       │
└────────────────┬────────────────────────┘
                 │ HTTP
┌────────────────▼────────────────────────┐
│      API Client (Retrofit)               │
│  (Type-safe endpoints, Authentication)   │
└────────────────┬────────────────────────┘
                 │ REST
┌────────────────▼────────────────────────┐
│      Backend Services (Moqui)            │
│  (Business logic, Database)              │
└─────────────────────────────────────────┘
```

### Data Flow Patterns

#### 1. List Assessments
```
ListAssessmentsEvent(page, pageSize, status)
    ↓
AssessmentBloc
    ↓
emit(AssessmentLoading)
    ↓
AssessmentRepository.listAssessments()
    ↓
AssessmentApiClient.listAssessments()
    ↓
[API Call] GET /services/assessments
    ↓
Response: List<Assessment>
    ↓
emit(AssessmentsLoaded(assessments, totalCount, page, pageSize))
```

#### 2. Submit Assessment
```
SubmitAssessmentEvent(assessmentId, answers, respondentInfo)
    ↓
AssessmentBloc
    ↓
emit(AssessmentLoading)
    ↓
AssessmentRepository.submitAssessment()
    ↓
AssessmentApiClient.submitAssessment()
    ↓
[API Call] POST /services/assessments/{id}/submit
    ↓
Backend: Calculates score, determines lead status
    ↓
Response: AssessmentResult(score, leadStatus)
    ↓
emit(AssessmentSubmitted(result))
```

#### 3. Calculate Score with Lead Status
```
CalculateScoreEvent(assessmentId, answers)
    ↓
AssessmentBloc
    ↓
AssessmentService.scoreAssessment()
    ↓
1. Calculate score via API
2. Fetch thresholds
3. Determine lead status
    ↓
emit(ScoreCalculated(score, leadStatus))
```

---

## Components

### 1. Models (Data Layer)

#### Assessment
```dart
Assessment(
  assessmentId: 'system-wide-unique-id',
  pseudoId: 'tenant-unique-id',
  ownerPartyId: 'company-id',
  assessmentName: 'Product Readiness Assessment',
  description: 'Evaluate product market readiness',
  status: 'ACTIVE',
  createdDate: DateTime.now(),
)
```

**Usage**:
- Represents a survey/assessment
- Unique at system level (assessmentId)
- Unique at tenant level (pseudoId)
- Owned by company (ownerPartyId)

---

#### AssessmentQuestion
```dart
AssessmentQuestion(
  questionId: 'question-unique-id',
  pseudoId: 'question-tenant-id',
  assessmentId: 'parent-assessment-id',
  questionSequence: 1,
  questionType: 'multiselect', // or 'text', 'score'
  questionText: 'How ready is your product?',
  isRequired: true,
  createdDate: DateTime.now(),
)
```

**Usage**:
- Individual questions within assessment
- Ordered by sequence
- Multiple question types supported
- Required field validation support

---

#### AssessmentQuestionOption
```dart
AssessmentQuestionOption(
  optionId: 'option-unique-id',
  pseudoId: 'option-tenant-id',
  questionId: 'parent-question-id',
  assessmentId: 'context-assessment-id',
  optionSequence: 1,
  optionText: 'Fully ready',
  optionScore: 10.0, // Points for this option
  createdDate: DateTime.now(),
)
```

**Usage**:
- Answer options for multiple choice questions
- Each option can have a point value
- Used in score calculation

---

#### ScoringThreshold
```dart
ScoringThreshold(
  thresholdId: 'threshold-unique-id',
  pseudoId: 'threshold-tenant-id',
  assessmentId: 'parent-assessment-id',
  minScore: 67.0,
  maxScore: 100.0,
  leadStatus: 'hot',
  description: 'Highly qualified lead',
  createdDate: DateTime.now(),
)
```

**Usage**:
- Maps score ranges to lead categories
- Typically 3 thresholds (Cold: 0-33, Warm: 34-66, Hot: 67-100)
- Determines lead status after submission

---

#### AssessmentResult
```dart
AssessmentResult(
  resultId: 'result-unique-id',
  pseudoId: 'result-tenant-id',
  assessmentId: 'completed-assessment-id',
  ownerPartyId: 'assessment-owner-company-id',
  score: 85.0,
  leadStatus: 'hot',
  respondentName: 'John Doe',
  respondentEmail: 'john@example.com',
  respondentPhone: '+1-555-0123',
  respondentCompany: 'Acme Corp',
  answersData: '{"q1": "opt1", "q2": "opt2"}',
  createdDate: DateTime.now(),
)
```

**Usage**:
- Records assessment submission
- Stores respondent information
- Captures answers and calculated score
- Assigns lead status

---

### 2. API Client (Network Layer)

#### AssessmentApiClient

**22 Endpoints organized by resource**:

**Assessments** (6 endpoints):
- `getAssessment(id)` - Retrieve single assessment
- `listAssessments(start, limit, search, statusId)` - List with pagination
- `createAssessment(assessment)` - Create new
- `updateAssessment(id, assessment)` - Update existing
- `deleteAssessment(id)` - Delete
- `submitAssessment(id, result)` - Submit with lead capture

**Questions** (4 endpoints):
- `createQuestion(assessmentId, question)` - Add question
- `updateQuestion(assessmentId, questionId, question)` - Modify
- `deleteQuestion(assessmentId, questionId)` - Remove
- `listQuestions(assessmentId, start, limit)` - Get all

**Options** (4 endpoints):
- `createOption(assessmentId, questionId, option)` - Add option
- `updateOption(assessmentId, questionId, optionId, option)` - Modify
- `deleteOption(assessmentId, questionId, optionId)` - Remove
- `listOptions(assessmentId, questionId, start, limit)` - Get all

**Scoring** (3 endpoints):
- `getThresholds(assessmentId)` - Retrieve score ranges
- `updateThresholds(assessmentId, thresholds)` - Set ranges
- `calculateScore(assessmentId, answers)` - Compute score

**Results** (3 endpoints):
- `listResults(assessmentId, start, limit, statusId)` - Paginated results
- `getResult(assessmentId, resultId)` - Single result
- `deleteResult(assessmentId, resultId)` - Remove result

---

### 3. Repository (Data Access Layer)

#### AssessmentRepository

**Primary Methods**:

```dart
// Get single assessment with all context
Future<Assessment> getAssessment(String assessmentId)

// List assessments with pagination and filtering
Future<AssessmentListResponse> listAssessments({
  int start = 0,
  int limit = 20,
  String? statusId,
})

// Create new assessment
Future<Assessment> createAssessment({
  required String assessmentName,
  String? description,
  String status = 'ACTIVE',
})

// Update assessment
Future<Assessment> updateAssessment({
  required String assessmentId,
  String? assessmentName,
  String? description,
  String? status,
})

// Delete assessment
Future<void> deleteAssessment(String assessmentId)

// Submit assessment responses
Future<AssessmentResult> submitAssessment({
  required String assessmentId,
  required Map<String, dynamic> answers,
  required String respondentName,
  required String respondentEmail,
  String? respondentPhone,
  String? respondentCompany,
})

// Get questions for assessment
Future<List<AssessmentQuestion>> getQuestions(String assessmentId)

// Get options for question
Future<List<AssessmentQuestionOption>> getOptions(
  String assessmentId,
  String questionId,
)

// Get scoring thresholds
Future<List<ScoringThreshold>> getThresholds(String assessmentId)

// Calculate score from answers
Future<double> calculateScore(
  String assessmentId,
  Map<String, dynamic> answers,
)

// Get assessment results
Future<List<AssessmentResult>> getResults(
  String assessmentId, {
  int start = 0,
  int limit = 20,
})
```

**Error Handling**:
- Comprehensive Dio exception mapping
- User-friendly error messages
- Automatic logging
- Stack trace preservation

---

### 4. Service (Business Logic Layer)

#### AssessmentService

**Key Methods**:

```dart
// Determine lead status from score
Future<String> determineLeadStatus(
  String assessmentId,
  double score,
)

// Get assessment with all related data
Future<AssessmentContext> getAssessmentContext(String assessmentId)

// Validate answers before submission
ValidationResult validateAnswers(
  List<AssessmentQuestion> questions,
  Map<String, dynamic> answers,
)

// Calculate score and determine status
Future<ScoreResult> scoreAssessment(
  String assessmentId,
  Map<String, dynamic> answers,
)

// Get assessment progress
Future<AssessmentProgress> getAssessmentProgress(String assessmentId)

// Get paginated results
Future<AssessmentResultsPage> getAssessmentResults(
  String assessmentId, {
  int page = 1,
  int pageSize = 20,
})

// Analyze results with statistics
Future<AssessmentAnalytics> analyzeResults(String assessmentId)
```

**Data Classes**:

```dart
// Complete assessment context
class AssessmentContext {
  final Assessment assessment;
  final List<AssessmentQuestion> questions;
  final Map<String, List<AssessmentQuestionOption>> options;
  final List<ScoringThreshold> thresholds;
}

// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
}

// Score result
class ScoreResult {
  final double score;
  final String leadStatus;
}

// Progress tracking
class AssessmentProgress {
  final String assessmentId;
  final String assessmentName;
  final int totalQuestions;
  final int requiredQuestions;
  final int questionsWithOptions;
  double get completionPercentage => ...;
}

// Paginated results
class AssessmentResultsPage {
  final List<AssessmentResult> results;
  final int page;
  final int pageSize;
  final int? totalCount;
}

// Analytics with statistics
class AssessmentAnalytics {
  final String assessmentId;
  final int totalResponses;
  final double averageScore;
  final Map<String, int> leadStatusDistribution;
  final Map<String, int> scoreDistribution;
  String? get mostCommonLeadStatus => ...;
}
```

---

### 5. BLoC (State Management)

#### AssessmentBloc

**Events** (9 types):
- `GetAssessmentEvent` - Load single assessment
- `ListAssessmentsEvent` - Load assessment list
- `CreateAssessmentEvent` - Create assessment
- `UpdateAssessmentEvent` - Update assessment
- `DeleteAssessmentEvent` - Delete assessment
- `LoadQuestionsEvent` - Load questions
- `LoadThresholdsEvent` - Load thresholds
- `SubmitAssessmentEvent` - Submit assessment
- `CalculateScoreEvent` - Calculate score

**States** (13 types):
- `AssessmentInitial` - Initial/idle state
- `AssessmentLoading` - Loading state
- `AssessmentLoaded` - Assessment loaded
- `AssessmentsLoaded` - List loaded
- `AssessmentCreated` - Creation success
- `AssessmentUpdated` - Update success
- `AssessmentDeleted` - Deletion success
- `QuestionsLoaded` - Questions loaded
- `ThresholdsLoaded` - Thresholds loaded
- `AssessmentSubmitted` - Submission success
- `ScoreCalculated` - Score calculated
- `AssessmentError` - Error occurred

**Usage Pattern**:

```dart
// Trigger event
bloc.add(GetAssessmentEvent('assessment_123'));

// Listen to state
bloc.stream.listen((state) {
  if (state is AssessmentLoading) {
    // Show loading indicator
  } else if (state is AssessmentLoaded) {
    // Update UI with assessment
  } else if (state is AssessmentError) {
    // Show error message
  }
});
```

---

## Usage Examples

### Example 1: Load and Display Assessment

```dart
class AssessmentListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state is AssessmentLoading) {
          return const CircularProgressIndicator();
        }
        
        if (state is AssessmentsLoaded) {
          return ListView.builder(
            itemCount: state.assessments.length,
            itemBuilder: (context, index) {
              final assessment = state.assessments[index];
              return ListTile(
                title: Text(assessment.assessmentName),
                subtitle: Text(assessment.description ?? ''),
                onTap: () {
                  context.read<AssessmentBloc>().add(
                    GetAssessmentEvent(assessment.assessmentId),
                  );
                },
              );
            },
          );
        }
        
        if (state is AssessmentError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
```

### Example 2: Validate and Submit Assessment

```dart
class SubmitAssessmentScreen extends StatefulWidget {
  final AssessmentContext context;
  
  @override
  State<SubmitAssessmentScreen> createState() => _SubmitAssessmentScreenState();
}

class _SubmitAssessmentScreenState extends State<SubmitAssessmentScreen> {
  final answers = <String, dynamic>{};
  
  void _submit() {
    // Validate
    final service = context.read<AssessmentService>();
    final validation = service.validateAnswers(
      widget.context.questions,
      answers,
    );
    
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.errors.join(', '))),
      );
      return;
    }
    
    // Submit
    context.read<AssessmentBloc>().add(
      SubmitAssessmentEvent(
        assessmentId: widget.context.assessment.assessmentId,
        answers: answers,
        respondentName: 'John Doe',
        respondentEmail: 'john@example.com',
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state is AssessmentSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Score: ${state.result.score}, Status: ${state.result.leadStatus}')),
          );
        } else if (state is AssessmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: ElevatedButton(
        onPressed: _submit,
        child: const Text('Submit Assessment'),
      ),
    );
  }
}
```

### Example 3: Calculate Score in Real-time

```dart
class ScorePreviewWidget extends StatelessWidget {
  final String assessmentId;
  final Map<String, dynamic> answers;
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<AssessmentBloc>().add(
                  CalculateScoreEvent(
                    assessmentId: assessmentId,
                    answers: answers,
                  ),
                );
              },
              child: const Text('Preview Score'),
            ),
            if (state is ScoreCalculated) ...[
              Text('Score: ${state.score}'),
              Text('Status: ${state.leadStatus ?? 'Unknown'}'),
            ],
          ],
        );
      },
    );
  }
}
```

### Example 4: Get Analytics

```dart
class AnalyticsScreen extends StatefulWidget {
  final String assessmentId;
  
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<AssessmentAnalytics> _analyticsFuture;
  
  @override
  void initState() {
    super.initState();
    final service = context.read<AssessmentService>();
    _analyticsFuture = service.analyzeResults(widget.assessmentId);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssessmentAnalytics>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final analytics = snapshot.data!;
        return Column(
          children: [
            Text('Total Responses: ${analytics.totalResponses}'),
            Text('Average Score: ${analytics.averageScore.toStringAsFixed(2)}'),
            Text('Most Common Status: ${analytics.mostCommonLeadStatus}'),
            ...analytics.leadStatusDistribution.entries.map((e) =>
              Text('${e.key}: ${e.value}'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## API Reference

### Assessment Endpoints

#### Get Assessment
```
GET /services/assessments/{assessmentId}
Headers: Authorization: Bearer {token}
Response: Assessment
```

#### List Assessments
```
GET /services/assessments?start=0&limit=20&statusId=ACTIVE
Headers: Authorization: Bearer {token}
Response: {assessments: List<Assessment>, totalCount: int, pageCount: int}
```

#### Create Assessment
```
POST /services/assessments
Headers: Authorization: Bearer {token}
Body: {assessmentName, description?, status?}
Response: Assessment
```

#### Update Assessment
```
PUT /services/assessments/{assessmentId}
Headers: Authorization: Bearer {token}
Body: {assessmentName?, description?, status?}
Response: Assessment
```

#### Delete Assessment
```
DELETE /services/assessments/{assessmentId}
Headers: Authorization: Bearer {token}
Response: {deletedCount: int}
```

#### Submit Assessment
```
POST /services/assessments/{assessmentId}/submit
Headers: Authorization: Bearer {token}? (public submission allowed)
Body: {
  answersData: JSON string,
  respondentName,
  respondentEmail,
  respondentPhone?,
  respondentCompany?
}
Response: AssessmentResult {resultId, score, leadStatus}
```

---

## Testing

### Unit Tests

Run service layer tests:
```bash
flutter test test/service/assessment_service_test.dart
```

**Test Coverage** (18 tests):
- Score determination
- Answer validation
- Progress calculation
- Score calculation
- Result retrieval
- Analytics generation

### Integration Tests

Run full end-to-end tests (backend required):
```bash
flutter test integration_test/assessment_flow_test.dart
```

**Test Scenarios**:
- Create assessment
- Add questions and options
- Load assessment with all data
- Submit assessment with scoring
- Retrieve results
- Analyze results

### Widget Tests

Test UI components:
```bash
flutter test test/widgets/
```

---

## Troubleshooting

### Common Issues

#### 1. "No assessment found" Error
**Cause**: Assessment doesn't exist or wrong ID provided  
**Solution**: Verify assessmentId is correct, check if assessment was created

#### 2. "Unauthorized" Error
**Cause**: Missing or invalid authentication token  
**Solution**: Ensure JWT token is included in Authorization header

#### 3. "Score calculation failed"
**Cause**: Invalid answers or missing options  
**Solution**: Validate answers before submission using `validateAnswers()`

#### 4. "Network timeout"
**Cause**: Backend service is slow or unreachable  
**Solution**: Check backend connectivity, increase timeout if needed

#### 5. "Build generation failed"
**Cause**: Models not generated  
**Solution**: Run `flutter pub run build_runner build`

### Debug Tips

1. **Enable logging**:
```dart
final logger = Logger();
// Logs are printed to console
```

2. **Check BLoC state transitions**:
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    print('State: $state');
  },
)
```

3. **Inspect API responses**:
```dart
// Enable Dio logging
dio.interceptors.add(LoggingInterceptor());
```

4. **Test repository directly**:
```dart
final repo = AssessmentRepository(...);
final assessment = await repo.getAssessment('id');
print(assessment);
```

---

## Best Practices

1. **Always validate answers before submission**
```dart
final validation = service.validateAnswers(questions, answers);
if (!validation.isValid) {
  // Show errors
}
```

2. **Use BlocListener for side effects**
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentSubmitted) {
      // Navigate, show snackbar, etc.
    }
  },
)
```

3. **Use BlocBuilder for UI updates**
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) => ...,
)
```

4. **Cache assessment context**
```dart
final context = await service.getAssessmentContext(assessmentId);
// Reuse for questions, options, thresholds
```

5. **Implement proper error handling**
```dart
try {
  await repository.submitAssessment(...);
} catch (e) {
  // Show user-friendly error
}
```

---

## Performance Considerations

- **Pagination**: Use `limit` parameter to reduce data transfer
- **Caching**: Store frequently accessed data (questions, options)
- **Batch operations**: Load all questions/options at once, not individually
- **Lazy loading**: Load thresholds only when needed for scoring

---

## Security Notes

- **Authentication**: All admin endpoints require JWT token
- **Public submission**: Assessment submission is public (no auth required)
- **Multi-tenant**: Data automatically filtered by authenticated user's company
- **No client-side tenancy override**: Owner party ID cannot be spoofed from client

---

**For more information, see:**
- [Backend API Reference](ASSESSMENT_API_REFERENCE.md)
- [Integration Documentation](PHASE_1_BACKEND_FRONTEND_INTEGRATION.md)
- [Architecture Guide](GrowERP_Extensibility_Guide.md)
