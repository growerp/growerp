# Service Layer Guide

**Component**: AssessmentService  
**Package**: growerp_assessment  
**Version**: 1.9.0

## Overview

AssessmentService provides high-level business logic for assessment operations. It encapsulates validation, scoring, analytics, and data context management.

---

## Architecture

```
UI Layer (Screens)
       ↓
AssessmentBloc (State Management)
       ↓
AssessmentService (Business Logic)
  ├─ Score Calculation
  ├─ Answer Validation
  ├─ Progress Tracking
  ├─ Analytics
  └─ Context Loading
       ↓
AssessmentRepository (Data Access)
       ↓
API Client (HTTP)
```

---

## Methods

### 1. determineLeadStatus()

**Purpose**: Map score to lead status

**Signature**:
```dart
Future<String> determineLeadStatus(
  String assessmentId,
  double score,
)
```

**Usage**:
```dart
final status = await service.determineLeadStatus(
  'assessment_123',
  85.5,
);
print(status); // 'hot', 'warm', or 'cold'
```

**Returns**: Lead status string ('hot', 'warm', 'cold', or custom)

**Example Flow**:
```
Score: 0-33    → Status: 'cold'
Score: 34-66   → Status: 'warm'
Score: 67-100  → Status: 'hot'
```

**Error Handling**:
```dart
try {
  final status = await service.determineLeadStatus(id, score);
  print('Lead status: $status');
} catch (e) {
  print('Error: $e');
  // Handle error (invalid assessment, thresholds not configured, etc.)
}
```

---

### 2. getAssessmentContext()

**Purpose**: Load complete assessment with all related data

**Signature**:
```dart
Future<AssessmentContext> getAssessmentContext(String assessmentId)
```

**Returns**:
```dart
class AssessmentContext {
  final Assessment assessment;
  final List<AssessmentQuestion> questions;
  final Map<String, List<AssessmentQuestionOption>> options;
  final List<ScoringThreshold> thresholds;
}
```

**Usage**:
```dart
final context = await service.getAssessmentContext('assessment_123');

// Access all related data
print('Assessment: ${context.assessment.assessmentName}');
print('Questions: ${context.questions.length}');
print('Thresholds: ${context.thresholds.length}');

// Get options for specific question
final questionId = context.questions[0].questionId;
final options = context.options[questionId];
print('Options: ${options?.length}');
```

**Typical Use Case** - Pre-load all data before displaying assessment:
```dart
@override
void initState() {
  super.initState();
  _loadContext();
}

Future<void> _loadContext() async {
  try {
    final context = await widget.service
      .getAssessmentContext(widget.assessmentId);
    
    setState(() {
      assessment = context.assessment;
      questions = context.questions;
      options = context.options;
      thresholds = context.thresholds;
    });
  } catch (e) {
    print('Error loading context: $e');
  }
}
```

**Performance Note**: Loads all data at once - good for form display, not for initial page load

---

### 3. validateAnswers()

**Purpose**: Validate user responses before submission

**Signature**:
```dart
ValidationResult validateAnswers(
  List<AssessmentQuestion> questions,
  Map<String, dynamic> answers,
)
```

**Returns**:
```dart
class ValidationResult {
  final bool isValid;
  final List<String> errors;
}
```

**Usage**:
```dart
final answers = {
  'question_1': 'option_1',
  'question_2': 'option_2',
};

final result = service.validateAnswers(questions, answers);

if (result.isValid) {
  print('All answers valid');
} else {
  print('Validation errors:');
  for (final error in result.errors) {
    print('  - $error');
  }
}
```

**Validation Rules**:
1. All required questions answered
2. Only valid options selected
3. Answer format matches question type
4. No duplicate answers for single-select

**Example - Before Submission**:
```dart
void _submitAssessment() {
  final validation = service.validateAnswers(
    questions,
    userAnswers,
  );
  
  if (!validation.isValid) {
    // Show errors to user
    showErrorDialog(
      context,
      'Validation Errors',
      validation.errors.join('\n'),
    );
    return;
  }
  
  // Proceed with submission
  bloc.add(SubmitAssessmentEvent(...));
}
```

**Custom Validation Example**:
```dart
final answers = {
  'question_1': 'option_1',
  'question_2': 'option_2',
};

final validation = service.validateAnswers(questions, answers);
final isValid = validation.isValid && 
  answers['question_1'] != 'option_default' &&
  answers['question_2'] != '';

if (!isValid) {
  // Handle custom validation
}
```

---

### 4. scoreAssessment()

**Purpose**: Calculate score and determine lead status

**Signature**:
```dart
Future<ScoreResult> scoreAssessment(
  String assessmentId,
  Map<String, dynamic> answers,
)
```

**Returns**:
```dart
class ScoreResult {
  final double score;
  final String leadStatus;
}
```

**Usage**:
```dart
final answers = {
  'question_1': 'option_1',
  'question_2': 'option_3',
};

final result = await service.scoreAssessment(
  'assessment_123',
  answers,
);

print('Score: ${result.score}');
print('Lead Status: ${result.leadStatus}');
```

**Complete Example**:
```dart
void _previewScore() async {
  try {
    final result = await service.scoreAssessment(
      assessmentId,
      userAnswers,
    );
    
    setState(() {
      previewScore = result.score;
      previewStatus = result.leadStatus;
    });
    
    // Show score preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Score Preview'),
        content: Column(
          children: [
            Text('Score: ${result.score.toStringAsFixed(1)}/100'),
            Text('Lead Status: ${result.leadStatus}'),
          ],
        ),
      ),
    );
  } catch (e) {
    print('Error calculating score: $e');
  }
}
```

**Scoring Algorithm**:
1. Get answer for each question
2. Look up option points for each answer
3. Sum all points
4. Map to score (normalized 0-100)
5. Determine status from thresholds

**Real-time Score Display**:
```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Answer form
      ...questions.map((q) =>
        AnswerOption(
          question: q,
          onChanged: (answer) async {
            answers[q.questionId] = answer;
            final result = await service.scoreAssessment(
              assessmentId,
              answers,
            );
            setState(() {
              currentScore = result.score;
              currentStatus = result.leadStatus;
            });
          },
        ),
      ),
      // Score display
      Card(
        child: Column(
          children: [
            Text('Current Score: $currentScore'),
            Text('Status: $currentStatus'),
          ],
        ),
      ),
    ],
  );
}
```

---

### 5. getAssessmentProgress()

**Purpose**: Track completion status of assessment

**Signature**:
```dart
Future<AssessmentProgress> getAssessmentProgress(String assessmentId)
```

**Returns**:
```dart
class AssessmentProgress {
  final String assessmentId;
  final String assessmentName;
  final int totalQuestions;
  final int requiredQuestions;
  final int questionsWithOptions;
  double get completionPercentage => 
    (questionsWithOptions / requiredQuestions) * 100;
}
```

**Usage**:
```dart
final progress = await service.getAssessmentProgress('assessment_123');

print('Assessment: ${progress.assessmentName}');
print('Total Questions: ${progress.totalQuestions}');
print('Completion: ${progress.completionPercentage.toStringAsFixed(1)}%');
```

**Progress Bar Example**:
```dart
FutureBuilder<AssessmentProgress>(
  future: service.getAssessmentProgress(assessmentId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final progress = snapshot.data!;
      return Column(
        children: [
          LinearProgressIndicator(
            value: progress.completionPercentage / 100,
          ),
          Text('${progress.questionsWithOptions}/${progress.requiredQuestions} complete'),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

### 6. analyzeResults()

**Purpose**: Generate analytics for assessment responses

**Signature**:
```dart
Future<AssessmentAnalytics> analyzeResults(String assessmentId)
```

**Returns**:
```dart
class AssessmentAnalytics {
  final String assessmentId;
  final int totalResponses;
  final double averageScore;
  final Map<String, int> leadStatusDistribution;
  final Map<String, int> scoreDistribution;
  String? get mostCommonLeadStatus => ...;
}
```

**Usage**:
```dart
final analytics = await service.analyzeResults('assessment_123');

print('Total Responses: ${analytics.totalResponses}');
print('Average Score: ${analytics.averageScore.toStringAsFixed(2)}');
print('Most Common Status: ${analytics.mostCommonLeadStatus}');

// Lead distribution
for (final entry in analytics.leadStatusDistribution.entries) {
  print('${entry.key}: ${entry.value}');
}
```

**Dashboard Example**:
```dart
class AnalyticsDashboard extends StatelessWidget {
  final String assessmentId;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssessmentAnalytics>(
      future: service.analyzeResults(assessmentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final analytics = snapshot.data!;
        
        return Column(
          children: [
            Card(
              child: Column(
                children: [
                  const Text('Response Statistics'),
                  Text('Total: ${analytics.totalResponses}'),
                  Text('Average Score: ${analytics.averageScore.toStringAsFixed(2)}'),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  const Text('Lead Status Distribution'),
                  ...analytics.leadStatusDistribution.entries.map((e) =>
                    Row(
                      children: [
                        Text('${e.key}:'),
                        Text('${e.value}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  const Text('Score Distribution'),
                  ...analytics.scoreDistribution.entries.map((e) =>
                    Row(
                      children: [
                        Text('${e.key}:'),
                        Text('${e.value}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Data Classes

### ValidationResult

```dart
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  bool get hasErrors => errors.isNotEmpty;
  int get errorCount => errors.length;
}
```

**Usage**:
```dart
final result = service.validateAnswers(questions, answers);
if (result.hasErrors) {
  print('${result.errorCount} validation error(s)');
  for (final error in result.errors) {
    print('  - $error');
  }
}
```

---

### ScoreResult

```dart
class ScoreResult {
  final double score;
  final String leadStatus;
  
  bool get isHot => leadStatus == 'hot';
  bool get isWarm => leadStatus == 'warm';
  bool get isCold => leadStatus == 'cold';
}
```

**Usage**:
```dart
final result = await service.scoreAssessment(assessmentId, answers);

if (result.isHot) {
  print('Qualified lead!');
} else if (result.isWarm) {
  print('Potential lead');
}
```

---

### AssessmentContext

```dart
class AssessmentContext {
  final Assessment assessment;
  final List<AssessmentQuestion> questions;
  final Map<String, List<AssessmentQuestionOption>> options;
  final List<ScoringThreshold> thresholds;
  
  // Helpers
  List<AssessmentQuestionOption> getOptionsForQuestion(String questionId) =>
    options[questionId] ?? [];
    
  ScoringThreshold? getThresholdForScore(double score) =>
    thresholds.firstWhereOrNull((t) =>
      score >= t.minScore && score <= t.maxScore);
}
```

**Usage**:
```dart
final context = await service.getAssessmentContext(assessmentId);

// Get options for first question
final firstQuestion = context.questions[0];
final options = context.getOptionsForQuestion(firstQuestion.questionId);

// Get threshold for score
final threshold = context.getThresholdForScore(85.0);
print('Status: ${threshold?.leadStatus}');
```

---

### AssessmentProgress

```dart
class AssessmentProgress {
  final String assessmentId;
  final String assessmentName;
  final int totalQuestions;
  final int requiredQuestions;
  final int questionsWithOptions;
  
  double get completionPercentage =>
    (questionsWithOptions / requiredQuestions) * 100;
    
  bool get isComplete =>
    questionsWithOptions == requiredQuestions;
}
```

**Usage**:
```dart
final progress = await service.getAssessmentProgress(assessmentId);
if (progress.isComplete) {
  print('Assessment is ready for publishing');
} else {
  print('Missing ${progress.requiredQuestions - progress.questionsWithOptions} questions');
}
```

---

### AssessmentResultsPage

```dart
class AssessmentResultsPage {
  final List<AssessmentResult> results;
  final int page;
  final int pageSize;
  final int? totalCount;
  
  int? get totalPages => totalCount != null
    ? (totalCount! / pageSize).ceil()
    : null;
    
  bool get hasNextPage => totalPages != null
    ? page < totalPages!
    : false;
}
```

**Usage**:
```dart
final page1 = await service.getAssessmentResults(
  assessmentId,
  page: 1,
  pageSize: 20,
);

print('Results: ${page1.results.length}');
print('Page ${page1.page} of ${page1.totalPages}');

if (page1.hasNextPage) {
  final page2 = await service.getAssessmentResults(
    assessmentId,
    page: 2,
    pageSize: 20,
  );
}
```

---

### AssessmentAnalytics

```dart
class AssessmentAnalytics {
  final String assessmentId;
  final int totalResponses;
  final double averageScore;
  final Map<String, int> leadStatusDistribution;
  final Map<String, int> scoreDistribution;
  
  String? get mostCommonLeadStatus {
    if (leadStatusDistribution.isEmpty) return null;
    return leadStatusDistribution.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }
  
  String get formattedAverage =>
    averageScore.toStringAsFixed(2);
    
  int get hotLeads =>
    leadStatusDistribution['hot'] ?? 0;
    
  int get warmLeads =>
    leadStatusDistribution['warm'] ?? 0;
    
  int get coldLeads =>
    leadStatusDistribution['cold'] ?? 0;
}
```

**Usage**:
```dart
final analytics = await service.analyzeResults(assessmentId);
print('Hot leads: ${analytics.hotLeads}');
print('Warm leads: ${analytics.warmLeads}');
print('Cold leads: ${analytics.coldLeads}');
print('Average: ${analytics.formattedAverage}');
```

---

## Common Patterns

### Pattern 1: Load-Display-Score Flow

```dart
class AssessmentFlow {
  Future<void> run(String assessmentId) async {
    // Step 1: Load context
    final context = await service.getAssessmentContext(assessmentId);
    
    // Step 2: Display questions
    displayQuestions(context.questions);
    
    // Step 3: Wait for user answers
    final answers = await getUserAnswers();
    
    // Step 4: Validate
    final validation = service.validateAnswers(
      context.questions,
      answers,
    );
    
    if (!validation.isValid) {
      showErrors(validation.errors);
      return;
    }
    
    // Step 5: Score
    final result = await service.scoreAssessment(
      assessmentId,
      answers,
    );
    
    // Step 6: Display result
    showResult(result.score, result.leadStatus);
  }
}
```

---

### Pattern 2: Real-time Score Preview

```dart
class RealTimeScoring {
  Future<void> setupScoreUpdates(String assessmentId) async {
    final context = await service.getAssessmentContext(assessmentId);
    
    onAnswerChanged = (questionId, answer) async {
      answers[questionId] = answer;
      
      // Validate
      final validation = service.validateAnswers(
        context.questions,
        answers,
      );
      
      if (!validation.isValid) {
        showErrors(validation.errors);
        return;
      }
      
      // Calculate score
      final result = await service.scoreAssessment(
        assessmentId,
        answers,
      );
      
      // Update UI
      updateScoreDisplay(result.score, result.leadStatus);
    };
  }
}
```

---

### Pattern 3: Assessment Analytics Dashboard

```dart
class AnalyticsDashboard {
  Future<void> loadAnalytics(String assessmentId) async {
    final analytics = await service.analyzeResults(assessmentId);
    final progress = await service.getAssessmentProgress(assessmentId);
    
    return {
      'totalResponses': analytics.totalResponses,
      'averageScore': analytics.averageScore,
      'hotLeads': analytics.hotLeads,
      'warmLeads': analytics.warmLeads,
      'coldLeads': analytics.coldLeads,
      'completion': progress.completionPercentage,
      'mostCommonStatus': analytics.mostCommonLeadStatus,
    };
  }
}
```

---

## Error Handling

### Try-Catch Pattern

```dart
try {
  final context = await service.getAssessmentContext(assessmentId);
  displayAssessment(context);
} on AssessmentNotFoundException catch (e) {
  showErrorSnackbar('Assessment not found: ${e.message}');
} on NetworkException catch (e) {
  showErrorSnackbar('Network error: ${e.message}');
} catch (e) {
  showErrorSnackbar('Unexpected error: $e');
}
```

### With Loading State

```dart
setState(() => isLoading = true);

try {
  final context = await service.getAssessmentContext(assessmentId);
  setState(() {
    this.context = context;
    isLoading = false;
  });
} catch (e) {
  setState(() {
    error = e.toString();
    isLoading = false;
  });
}
```

---

## Testing

### Mock Service

```dart
class MockAssessmentService extends Mock implements AssessmentService {}

void main() {
  test('validate answers should return errors for missing required', () {
    final service = MockAssessmentService();
    final questions = [
      AssessmentQuestion(
        questionId: 'q1',
        questionText: 'Required question',
        isRequired: true,
        ...
      ),
    ];
    final answers = {}; // Empty - missing required answer
    
    when(service.validateAnswers(questions, answers))
      .thenReturn(ValidationResult(
        isValid: false,
        errors: ['Question 1 is required'],
      ));
    
    final result = service.validateAnswers(questions, answers);
    expect(result.isValid, false);
    expect(result.errors.length, 1);
  });
}
```

---

## Best Practices

1. **Always validate before submission**
```dart
final validation = service.validateAnswers(questions, answers);
if (!validation.isValid) return;
```

2. **Load context once, reuse throughout**
```dart
final context = await service.getAssessmentContext(id);
// Use context.questions, context.options, context.thresholds
```

3. **Handle async operations properly**
```dart
try {
  final result = await service.scoreAssessment(id, answers);
} catch (e) {
  handleError(e);
}
```

4. **Cache analytics results**
```dart
late AssessmentAnalytics _analytics;
@override
void initState() {
  _loadAnalytics();
}
Future<void> _loadAnalytics() async {
  _analytics = await service.analyzeResults(assessmentId);
}
```

---

**For complete documentation, see:**
- [Developer Guide](DEVELOPER_GUIDE.md)
- [BLoC Usage Guide](BLoC_USAGE_GUIDE.md)
- [Repository Pattern Guide](REPOSITORY_PATTERN_GUIDE.md)
