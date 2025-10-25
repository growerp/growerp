# Repository Pattern Guide

**Component**: AssessmentRepository  
**Package**: growerp_assessment  
**Version**: 1.9.0

## Overview

AssessmentRepository provides the data access abstraction layer. It encapsulates all API interactions, error handling, and data transformation.

**Key Responsibilities**:
- HTTP communication via AssessmentApiClient
- Error handling and mapping
- Response transformation
- Logging and debugging
- Network resilience

---

## Architecture

```
Service Layer
       ↓
AssessmentRepository (Data Access Abstraction)
  ├─ Error Handling
  ├─ Logging
  ├─ Data Transformation
  └─ API Coordination
       ↓
AssessmentApiClient (Type-safe HTTP)
       ↓
Dio HTTP Client
       ↓
Backend Services
```

---

## Constructor

```dart
AssessmentRepository({
  required AssessmentApiClient apiClient,
  required Logger logger,
})
```

**Usage**:
```dart
final apiClient = AssessmentApiClient(dio, baseUrl: 'https://api.growerp.com');
final logger = Logger('AssessmentRepository');
final repository = AssessmentRepository(
  apiClient: apiClient,
  logger: logger,
);
```

---

## Methods

### 1. getAssessment()

**Purpose**: Retrieve single assessment by ID

**Signature**:
```dart
Future<Assessment> getAssessment(String assessmentId)
```

**Usage**:
```dart
try {
  final assessment = await repository.getAssessment('assessment_123');
  print('Assessment: ${assessment.assessmentName}');
} catch (e) {
  print('Error: $e');
}
```

**Error Handling**:
```dart
// DioException → RepositoryException
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  if (e.message.contains('404')) {
    print('Assessment not found');
  } else if (e.message.contains('401')) {
    print('Authentication required');
  }
}
```

**Internal Flow**:
```
getAssessment(id)
  ↓
Check if id is empty
  ↓
Call apiClient.getAssessment(id)
  ↓
Handle DioException if thrown
  ↓
Log success/error
  ↓
Return Assessment or throw exception
```

---

### 2. listAssessments()

**Purpose**: Retrieve paginated assessment list

**Signature**:
```dart
Future<AssessmentListResponse> listAssessments({
  int start = 0,
  int limit = 20,
  String? statusId,
})
```

**Returns**:
```dart
class AssessmentListResponse {
  final List<Assessment> assessments;
  final int totalCount;
  final int pageCount;
  final int page;
  final int pageSize;
}
```

**Usage**:
```dart
// Get first page
final response = await repository.listAssessments();
print('First page: ${response.assessments.length} items');
print('Total: ${response.totalCount}');

// Get page 2 (offset: 20)
final page2 = await repository.listAssessments(start: 20);

// Filter by status
final active = await repository.listAssessments(
  statusId: 'ACTIVE',
);
```

**Pagination Pattern**:
```dart
class PaginatedList extends StatefulWidget {
  @override
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  late AssessmentListResponse _response;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }
  
  Future<void> _loadPage(int page) async {
    final response = await repository.listAssessments(
      start: page * 20,
      limit: 20,
    );
    
    setState(() {
      _response = response;
      _currentPage = page;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          itemCount: _response.assessments.length,
          itemBuilder: (context, index) =>
            ListTile(
              title: Text(_response.assessments[index].assessmentName),
            ),
        ),
        Row(
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: () => _loadPage(_currentPage - 1),
                child: const Text('Previous'),
              ),
            Text('Page ${_currentPage + 1} of ${_response.pageCount}'),
            if (_currentPage < _response.pageCount - 1)
              ElevatedButton(
                onPressed: () => _loadPage(_currentPage + 1),
                child: const Text('Next'),
              ),
          ],
        ),
      ],
    );
  }
}
```

---

### 3. createAssessment()

**Purpose**: Create new assessment

**Signature**:
```dart
Future<Assessment> createAssessment({
  required String assessmentName,
  String? description,
  String status = 'ACTIVE',
})
```

**Usage**:
```dart
final assessment = await repository.createAssessment(
  assessmentName: 'Product Readiness',
  description: 'Evaluate product market readiness',
  status: 'DRAFT',
);

print('Created: ${assessment.assessmentId}');
```

**With Error Handling**:
```dart
try {
  final assessment = await repository.createAssessment(
    assessmentName: _nameController.text,
  );
  print('Created: ${assessment.pseudoId}');
} on RepositoryException catch (e) {
  if (e.message.contains('duplicate')) {
    print('Assessment name already exists');
  } else {
    print('Error: ${e.message}');
  }
}
```

**Form Integration**:
```dart
class CreateAssessmentForm extends StatefulWidget {
  @override
  State<CreateAssessmentForm> createState() => _CreateAssessmentFormState();
}

class _CreateAssessmentFormState extends State<CreateAssessmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final assessment = await widget.repository.createAssessment(
        assessmentName: _nameController.text,
        description: _descriptionController.text,
      );
      
      Navigator.pop(context, assessment);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Assessment Name'),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          ElevatedButton(
            onPressed: _create,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
```

---

### 4. updateAssessment()

**Purpose**: Update existing assessment

**Signature**:
```dart
Future<Assessment> updateAssessment({
  required String assessmentId,
  String? assessmentName,
  String? description,
  String? status,
})
```

**Usage**:
```dart
final updated = await repository.updateAssessment(
  assessmentId: 'assessment_123',
  assessmentName: 'New Name',
  status: 'ACTIVE',
);

print('Updated: ${updated.assessmentName}');
```

---

### 5. deleteAssessment()

**Purpose**: Delete assessment

**Signature**:
```dart
Future<void> deleteAssessment(String assessmentId)
```

**Usage**:
```dart
try {
  await repository.deleteAssessment('assessment_123');
  print('Deleted');
} catch (e) {
  print('Error: $e');
}
```

**Confirmation Pattern**:
```dart
void _confirmDelete(String assessmentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Assessment?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            try {
              await widget.repository.deleteAssessment(assessmentId);
              Navigator.pop(context);
              Navigator.pop(context); // Back to list
            } catch (e) {
              print('Error: $e');
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

---

### 6. submitAssessment()

**Purpose**: Submit assessment responses

**Signature**:
```dart
Future<AssessmentResult> submitAssessment({
  required String assessmentId,
  required Map<String, dynamic> answers,
  required String respondentName,
  required String respondentEmail,
  String? respondentPhone,
  String? respondentCompany,
})
```

**Usage**:
```dart
final answers = {
  'question_1': 'option_1',
  'question_2': 'option_3',
};

final result = await repository.submitAssessment(
  assessmentId: 'assessment_123',
  answers: answers,
  respondentName: 'John Doe',
  respondentEmail: 'john@example.com',
  respondentPhone: '+1-555-0123',
  respondentCompany: 'Acme Corp',
);

print('Score: ${result.score}');
print('Status: ${result.leadStatus}');
```

**Full Submission Flow**:
```dart
Future<void> submitAssessment() async {
  try {
    final result = await repository.submitAssessment(
      assessmentId: widget.assessmentId,
      answers: userAnswers,
      respondentName: _nameController.text,
      respondentEmail: _emailController.text,
      respondentPhone: _phoneController.text,
      respondentCompany: _companyController.text,
    );
    
    // Show success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Submitted'),
        content: Column(
          children: [
            Text('Score: ${result.score.toStringAsFixed(1)}'),
            Text('Lead Status: ${result.leadStatus}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  } on RepositoryException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  }
}
```

---

### 7. getQuestions()

**Purpose**: Load questions for assessment

**Signature**:
```dart
Future<List<AssessmentQuestion>> getQuestions(String assessmentId)
```

**Usage**:
```dart
final questions = await repository.getQuestions('assessment_123');
print('Questions: ${questions.length}');

for (final q in questions) {
  print('Q${q.questionSequence}: ${q.questionText}');
}
```

---

### 8. getOptions()

**Purpose**: Load options for question

**Signature**:
```dart
Future<List<AssessmentQuestionOption>> getOptions(
  String assessmentId,
  String questionId,
)
```

**Usage**:
```dart
final options = await repository.getOptions(
  'assessment_123',
  'question_1',
);

for (final option in options) {
  print('${option.optionText} (${option.optionScore} pts)');
}
```

---

### 9. getThresholds()

**Purpose**: Load scoring thresholds

**Signature**:
```dart
Future<List<ScoringThreshold>> getThresholds(String assessmentId)
```

**Usage**:
```dart
final thresholds = await repository.getThresholds('assessment_123');

for (final threshold in thresholds) {
  print('${threshold.minScore}-${threshold.maxScore}: ${threshold.leadStatus}');
}
```

---

### 10. calculateScore()

**Purpose**: Calculate score from answers

**Signature**:
```dart
Future<double> calculateScore(
  String assessmentId,
  Map<String, dynamic> answers,
)
```

**Usage**:
```dart
final answers = {
  'question_1': 'option_1',
  'question_2': 'option_3',
};

final score = await repository.calculateScore(
  'assessment_123',
  answers,
);

print('Score: $score');
```

---

### 11. getResults()

**Purpose**: Get assessment results

**Signature**:
```dart
Future<List<AssessmentResult>> getResults(
  String assessmentId, {
  int start = 0,
  int limit = 20,
})
```

**Usage**:
```dart
final results = await repository.getResults(
  'assessment_123',
  start: 0,
  limit: 20,
);

print('Results: ${results.length}');
for (final result in results) {
  print('${result.respondentName}: ${result.score} (${result.leadStatus})');
}
```

---

## Error Handling

### Exception Types

All API errors are converted to `RepositoryException`:

```dart
class RepositoryException implements Exception {
  final String message;
  final int? statusCode;
  final Exception? originalException;
  final StackTrace? stackTrace;
}
```

### Common Error Scenarios

#### 401 Unauthorized
```dart
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  if (e.statusCode == 401) {
    print('Authentication required - navigate to login');
    navigateToLogin();
  }
}
```

#### 404 Not Found
```dart
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  if (e.statusCode == 404) {
    print('Assessment not found');
  }
}
```

#### 500 Server Error
```dart
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  if (e.statusCode == 500) {
    print('Server error - please try again later');
  }
}
```

#### Network Error
```dart
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  if (e.originalException is SocketException) {
    print('Network error - check your connection');
  }
}
```

### Comprehensive Error Handler

```dart
String getErrorMessage(RepositoryException e) {
  switch (e.statusCode) {
    case 400:
      return 'Invalid request - check your input';
    case 401:
      return 'Authentication required';
    case 403:
      return 'You do not have permission';
    case 404:
      return 'Assessment not found';
    case 409:
      return 'Assessment already exists';
    case 500:
      return 'Server error - please try again';
    case 503:
      return 'Service unavailable - please try again later';
    default:
      if (e.originalException is SocketException) {
        return 'Network error - check your connection';
      }
      if (e.originalException is TimeoutException) {
        return 'Request timed out - please try again';
      }
      return e.message;
  }
}
```

---

## Logging

All operations are automatically logged:

```dart
// Logs include:
// - Operation start: 'Getting assessment: assessment_123'
// - Success: 'Successfully got assessment'
// - Error: 'Error getting assessment: 404 Not Found'
// - Stack trace on errors
```

Enable detailed logging:

```dart
logger.level = Level.FINE;
logger.onRecord.listen((record) {
  print('${record.level.name}: ${record.message}');
  if (record.stackTrace != null) {
    print(record.stackTrace);
  }
});
```

---

## Caching Strategy

Current implementation does not cache, but you can wrap the repository:

```dart
class CachedAssessmentRepository implements AssessmentRepository {
  final AssessmentRepository _repository;
  final Map<String, Assessment> _cache = {};
  
  @override
  Future<Assessment> getAssessment(String assessmentId) async {
    // Return from cache if available
    if (_cache.containsKey(assessmentId)) {
      return _cache[assessmentId]!;
    }
    
    // Fetch from repository
    final assessment = await _repository.getAssessment(assessmentId);
    
    // Cache for future use
    _cache[assessmentId] = assessment;
    
    return assessment;
  }
  
  // Clear cache when updated
  @override
  Future<Assessment> updateAssessment({
    required String assessmentId,
    String? assessmentName,
    String? description,
    String? status,
  }) async {
    final result = await _repository.updateAssessment(
      assessmentId: assessmentId,
      assessmentName: assessmentName,
      description: description,
      status: status,
    );
    
    _cache[assessmentId] = result;
    return result;
  }
}
```

---

## Testing

### Mock Repository

```dart
class MockAssessmentRepository extends Mock
    implements AssessmentRepository {}

void main() {
  test('getAssessment returns assessment', () async {
    final repository = MockAssessmentRepository();
    final assessment = Assessment(
      assessmentId: 'test_123',
      assessmentName: 'Test Assessment',
      pseudoId: 'test_pseudo',
      ownerPartyId: 'owner_123',
      description: 'Test',
      status: 'ACTIVE',
      createdDate: DateTime.now(),
    );
    
    when(repository.getAssessment('test_123'))
        .thenAnswer((_) async => assessment);
    
    final result = await repository.getAssessment('test_123');
    
    expect(result.assessmentId, 'test_123');
    expect(result.assessmentName, 'Test Assessment');
  });
  
  test('getAssessment throws on error', () async {
    final repository = MockAssessmentRepository();
    
    when(repository.getAssessment('missing'))
        .thenThrow(RepositoryException(
      message: 'Not found',
      statusCode: 404,
    ));
    
    expect(
      () => repository.getAssessment('missing'),
      throwsA(isA<RepositoryException>()),
    );
  });
}
```

---

## Best Practices

1. **Always handle exceptions**
```dart
try {
  final assessment = await repository.getAssessment(id);
} on RepositoryException catch (e) {
  handleError(e);
}
```

2. **Use meaningful IDs**
```dart
// Good
await repository.getAssessment('assessment_abc123');

// Bad
await repository.getAssessment('123');
```

3. **Validate input before calling repository**
```dart
if (assessmentId.isEmpty) {
  throw ArgumentError('Assessment ID cannot be empty');
}
final assessment = await repository.getAssessment(assessmentId);
```

4. **Don't catch generic Exception**
```dart
// Good
try {
  ...
} on RepositoryException catch (e) {
  ...
}

// Bad
try {
  ...
} catch (e) {
  // Too broad, might hide programming errors
}
```

5. **Log before throwing**
```dart
logger.fine('Getting assessment: $assessmentId');
try {
  return await apiClient.getAssessment(assessmentId);
} catch (e, st) {
  logger.severe('Error getting assessment', e, st);
  throw RepositoryException(message: e.toString());
}
```

---

## Performance Considerations

1. **Pagination**: Always paginate large result sets
```dart
// Good - paginated
final page1 = await repository.listAssessments(limit: 20);

// Bad - could be slow
final all = await repository.listAssessments(limit: 10000);
```

2. **Lazy loading**: Don't load unnecessary data
```dart
// Only get assessment
final assessment = await repository.getAssessment(id);

// Later, when needed
final questions = await repository.getQuestions(id);
```

3. **Batch operations**: Load related data together
```dart
// Good - one call gets everything
final context = await service.getAssessmentContext(id);

// Less efficient
final assessment = await repository.getAssessment(id);
final questions = await repository.getQuestions(id);
final thresholds = await repository.getThresholds(id);
```

---

**For complete documentation, see:**
- [Developer Guide](DEVELOPER_GUIDE.md)
- [BLoC Usage Guide](BLoC_USAGE_GUIDE.md)
- [Service Layer Guide](SERVICE_LAYER_GUIDE.md)
