# AssessmentBloc Usage Guide

**Component**: AssessmentBloc  
**Package**: growerp_assessment  
**Version**: 1.9.0

## Overview

AssessmentBloc is the centralized state management component for all assessment operations. It follows the BLoC pattern with clear event-driven architecture.

**Key Characteristics**:
- 9 event types for different operations
- 13 state types representing all possible states
- Automatic error handling and logging
- Clean separation of UI and business logic

---

## Architecture

```
Event Handler
    ↓
Event Type?
    ↓
├─ GetAssessmentEvent → AssessmentLoaded
├─ ListAssessmentsEvent → AssessmentsLoaded
├─ CreateAssessmentEvent → AssessmentCreated
├─ UpdateAssessmentEvent → AssessmentUpdated
├─ DeleteAssessmentEvent → AssessmentDeleted
├─ LoadQuestionsEvent → QuestionsLoaded
├─ LoadThresholdsEvent → ThresholdsLoaded
├─ SubmitAssessmentEvent → AssessmentSubmitted
└─ CalculateScoreEvent → ScoreCalculated
    ↓
On Error: AssessmentError
```

---

## Events

### 1. GetAssessmentEvent

**Purpose**: Load single assessment by ID

**Constructor**:
```dart
GetAssessmentEvent(
  String assessmentId,
  {bool loadRelated = true}, // Load questions, options, thresholds
)
```

**Usage**:
```dart
// Simple load
context.read<AssessmentBloc>().add(
  GetAssessmentEvent('assessment_123'),
);

// Load without related data
context.read<AssessmentBloc>().add(
  GetAssessmentEvent(
    'assessment_123',
    loadRelated: false,
  ),
);
```

**State Flow**:
```
Initial → GetAssessmentEvent → Loading → Loaded
```

**Error Handling**:
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentError) {
      print('Error: ${state.message}');
    }
  },
)
```

---

### 2. ListAssessmentsEvent

**Purpose**: Load paginated list of assessments

**Constructor**:
```dart
ListAssessmentsEvent({
  int start = 0,
  int limit = 20,
  String? statusId, // Filter by status
})
```

**Usage**:
```dart
// Get first page
context.read<AssessmentBloc>().add(ListAssessmentsEvent());

// Get page 2 (with 20 items per page)
context.read<AssessmentBloc>().add(
  ListAssessmentsEvent(start: 20, limit: 20),
);

// Filter by status
context.read<AssessmentBloc>().add(
  ListAssessmentsEvent(statusId: 'ACTIVE'),
);
```

**State Flow**:
```
Initial → ListAssessmentsEvent → Loading → AssessmentsLoaded
```

**Accessing Results**:
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is AssessmentsLoaded) {
      print('Total: ${state.totalCount}');
      print('Page: ${state.page}');
      print('Items: ${state.assessments.length}');
      
      return ListView.builder(
        itemCount: state.assessments.length,
        itemBuilder: (context, index) {
          return Text(state.assessments[index].assessmentName);
        },
      );
    }
  },
)
```

---

### 3. CreateAssessmentEvent

**Purpose**: Create new assessment

**Constructor**:
```dart
CreateAssessmentEvent({
  required String assessmentName,
  String? description,
  String status = 'ACTIVE',
})
```

**Usage**:
```dart
context.read<AssessmentBloc>().add(
  CreateAssessmentEvent(
    assessmentName: 'Product Readiness',
    description: 'Evaluate product market readiness',
    status: 'DRAFT',
  ),
);
```

**State Flow**:
```
Initial → CreateAssessmentEvent → Loading → AssessmentCreated
```

**Listen for Success**:
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentCreated) {
      print('Created: ${state.assessment.assessmentId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment created!')),
      );
    }
  },
)
```

---

### 4. UpdateAssessmentEvent

**Purpose**: Update existing assessment

**Constructor**:
```dart
UpdateAssessmentEvent(
  String assessmentId, {
  String? assessmentName,
  String? description,
  String? status,
})
```

**Usage**:
```dart
context.read<AssessmentBloc>().add(
  UpdateAssessmentEvent(
    'assessment_123',
    assessmentName: 'Updated Name',
    status: 'ACTIVE',
  ),
);
```

**State Flow**:
```
Initial → UpdateAssessmentEvent → Loading → AssessmentUpdated
```

---

### 5. DeleteAssessmentEvent

**Purpose**: Delete assessment

**Constructor**:
```dart
DeleteAssessmentEvent(String assessmentId)
```

**Usage**:
```dart
context.read<AssessmentBloc>().add(
  DeleteAssessmentEvent('assessment_123'),
);
```

**State Flow**:
```
Initial → DeleteAssessmentEvent → Loading → AssessmentDeleted
```

**Confirmation Pattern**:
```dart
void _confirmDelete(String assessmentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Assessment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<AssessmentBloc>().add(
              DeleteAssessmentEvent(assessmentId),
            );
            Navigator.pop(context);
            Navigator.pop(context); // Back to list
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

---

### 6. LoadQuestionsEvent

**Purpose**: Load questions for assessment

**Constructor**:
```dart
LoadQuestionsEvent(
  String assessmentId, {
  int start = 0,
  int limit = 100,
})
```

**Usage**:
```dart
context.read<AssessmentBloc>().add(
  LoadQuestionsEvent('assessment_123'),
);
```

**State Flow**:
```
Initial → LoadQuestionsEvent → Loading → QuestionsLoaded
```

**Access Questions**:
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is QuestionsLoaded) {
      return ListView.builder(
        itemCount: state.questions.length,
        itemBuilder: (context, index) {
          final q = state.questions[index];
          return Card(
            child: ListTile(
              title: Text('Q${q.questionSequence}: ${q.questionText}'),
              subtitle: Text('Type: ${q.questionType}'),
            ),
          );
        },
      );
    }
  },
)
```

---

### 7. LoadThresholdsEvent

**Purpose**: Load scoring thresholds

**Constructor**:
```dart
LoadThresholdsEvent(String assessmentId)
```

**Usage**:
```dart
context.read<AssessmentBloc>().add(
  LoadThresholdsEvent('assessment_123'),
);
```

**State Flow**:
```
Initial → LoadThresholdsEvent → Loading → ThresholdsLoaded
```

**Display Thresholds**:
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is ThresholdsLoaded) {
      return Column(
        children: state.thresholds.map((t) =>
          Card(
            child: Column(
              children: [
                Text('${t.minScore} - ${t.maxScore}'),
                Text('Status: ${t.leadStatus}'),
                Text('${t.description}'),
              ],
            ),
          ),
        ).toList(),
      );
    }
  },
)
```

---

### 8. SubmitAssessmentEvent

**Purpose**: Submit assessment responses

**Constructor**:
```dart
SubmitAssessmentEvent({
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
  'question_1': 'option_3',
  'question_2': 'option_1',
  'question_3': 'text response',
};

context.read<AssessmentBloc>().add(
  SubmitAssessmentEvent(
    assessmentId: 'assessment_123',
    answers: answers,
    respondentName: 'John Doe',
    respondentEmail: 'john@example.com',
    respondentPhone: '+1-555-0123',
    respondentCompany: 'Acme Corp',
  ),
);
```

**State Flow**:
```
Initial → SubmitAssessmentEvent → Loading → AssessmentSubmitted
```

**Validation Before Submit**:
```dart
void _submitAssessment() {
  final service = context.read<AssessmentService>();
  final validation = service.validateAnswers(
    questions,
    answers,
  );
  
  if (!validation.isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(validation.errors.join(', '))),
    );
    return;
  }
  
  // All validated, submit
  context.read<AssessmentBloc>().add(
    SubmitAssessmentEvent(
      assessmentId: assessmentId,
      answers: answers,
      respondentName: respondentName,
      respondentEmail: respondentEmail,
    ),
  );
}
```

**Listen for Result**:
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentSubmitted) {
      print('Score: ${state.result.score}');
      print('Lead Status: ${state.result.leadStatus}');
      
      // Navigate to results screen
      Navigator.pushNamed(context, '/results', arguments: state.result);
    }
  },
)
```

---

### 9. CalculateScoreEvent

**Purpose**: Calculate score without submitting

**Constructor**:
```dart
CalculateScoreEvent({
  required String assessmentId,
  required Map<String, dynamic> answers,
})
```

**Usage** (Real-time Preview):
```dart
// Update preview as user answers questions
void _onAnswerChanged(String questionId, String answer) {
  answers[questionId] = answer;
  
  context.read<AssessmentBloc>().add(
    CalculateScoreEvent(
      assessmentId: assessmentId,
      answers: answers,
    ),
  );
}
```

**State Flow**:
```
Initial → CalculateScoreEvent → Loading → ScoreCalculated
```

**Display Score**:
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is ScoreCalculated) {
      return Card(
        child: Column(
          children: [
            Text('Current Score: ${state.score.toStringAsFixed(1)}'),
            if (state.leadStatus != null)
              Text('Status: ${state.leadStatus}'),
          ],
        ),
      );
    }
  },
)
```

---

## States

### AssessmentInitial
Initial state before any operation
```dart
if (state is AssessmentInitial) {
  return const SizedBox.shrink(); // No UI
}
```

### AssessmentLoading
Operation in progress
```dart
if (state is AssessmentLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

### AssessmentLoaded
Single assessment loaded successfully
```dart
if (state is AssessmentLoaded) {
  return Column(
    children: [
      Text(state.assessment.assessmentName),
      Text(state.assessment.description ?? ''),
    ],
  );
}
```

**Properties**:
```dart
class AssessmentLoaded extends AssessmentState {
  final Assessment assessment;
  final List<AssessmentQuestion>? questions;
  final List<ScoringThreshold>? thresholds;
}
```

### AssessmentsLoaded
Assessment list loaded successfully
```dart
if (state is AssessmentsLoaded) {
  return ListView.builder(
    itemCount: state.assessments.length,
    itemBuilder: (context, index) =>
      Text(state.assessments[index].assessmentName),
  );
}
```

**Properties**:
```dart
class AssessmentsLoaded extends AssessmentState {
  final List<Assessment> assessments;
  final int page;
  final int pageSize;
  final int totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}
```

### AssessmentCreated
Assessment created successfully
```dart
if (state is AssessmentCreated) {
  print('Created ID: ${state.assessment.assessmentId}');
}
```

### AssessmentUpdated
Assessment updated successfully
```dart
if (state is AssessmentUpdated) {
  print('Updated: ${state.assessment.assessmentName}');
}
```

### AssessmentDeleted
Assessment deleted successfully
```dart
if (state is AssessmentDeleted) {
  // Navigate back to list
  Navigator.pop(context);
}
```

### QuestionsLoaded
Questions loaded successfully
```dart
if (state is QuestionsLoaded) {
  return ListView(
    children: state.questions.map((q) =>
      Text('Q${q.questionSequence}: ${q.questionText}'),
    ).toList(),
  );
}
```

### ThresholdsLoaded
Thresholds loaded successfully
```dart
if (state is ThresholdsLoaded) {
  final warmThreshold = state.thresholds
    .firstWhere((t) => t.leadStatus == 'warm');
  print('Warm: ${warmThreshold.minScore}-${warmThreshold.maxScore}');
}
```

### AssessmentSubmitted
Assessment submitted successfully
```dart
if (state is AssessmentSubmitted) {
  showResultDialog(context, state.result);
}
```

**Properties**:
```dart
class AssessmentSubmitted extends AssessmentState {
  final AssessmentResult result;
}
```

### ScoreCalculated
Score calculated successfully
```dart
if (state is ScoreCalculated) {
  return Text('Score: ${state.score}, Status: ${state.leadStatus}');
}
```

**Properties**:
```dart
class ScoreCalculated extends AssessmentState {
  final double score;
  final String? leadStatus;
}
```

### AssessmentError
Error occurred
```dart
if (state is AssessmentError) {
  return Center(
    child: Column(
      children: [
        const Icon(Icons.error, color: Colors.red, size: 48),
        Text(state.message),
      ],
    ),
  );
}
```

**Properties**:
```dart
class AssessmentError extends AssessmentState {
  final String message;
  final StackTrace? stackTrace;
  final Exception? exception;
}
```

---

## Common Patterns

### Pattern 1: Load and Display

```dart
@override
void initState() {
  super.initState();
  // Load on screen init
  context.read<AssessmentBloc>().add(
    GetAssessmentEvent(widget.assessmentId),
  );
}

@override
Widget build(BuildContext context) {
  return BlocBuilder<AssessmentBloc, AssessmentState>(
    builder: (context, state) {
      if (state is AssessmentLoading) {
        return const CircularProgressIndicator();
      }
      if (state is AssessmentLoaded) {
        return AssessmentDetails(assessment: state.assessment);
      }
      if (state is AssessmentError) {
        return ErrorWidget(message: state.message);
      }
      return const SizedBox.shrink();
    },
  );
}
```

### Pattern 2: List with Pagination

```dart
class AssessmentListScreen extends StatefulWidget {
  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  int _page = 0;
  
  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }
  
  void _loadPage(int page) {
    setState(() => _page = page);
    context.read<AssessmentBloc>().add(
      ListAssessmentsEvent(start: page * 20, limit: 20),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<AssessmentBloc, AssessmentState>(
            builder: (context, state) {
              if (state is AssessmentsLoaded) {
                return ListView.builder(
                  itemCount: state.assessments.length,
                  itemBuilder: (context, index) =>
                    ListTile(
                      title: Text(state.assessments[index].assessmentName),
                    ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        if (state is AssessmentsLoaded)
          Row(
            children: [
              if (_page > 0)
                ElevatedButton(
                  onPressed: () => _loadPage(_page - 1),
                  child: const Text('Previous'),
                ),
              Text('Page ${_page + 1} of ${state.totalPages}'),
              if (_page < state.totalPages - 1)
                ElevatedButton(
                  onPressed: () => _loadPage(_page + 1),
                  child: const Text('Next'),
                ),
            ],
          ),
      ],
    );
  }
}
```

### Pattern 3: Create with Validation

```dart
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();

void _create() {
  if (!_formKey.currentState!.validate()) return;
  
  context.read<AssessmentBloc>().add(
    CreateAssessmentEvent(
      assessmentName: _nameController.text,
    ),
  );
}

@override
Widget build(BuildContext context) {
  return BlocListener<AssessmentBloc, AssessmentState>(
    listener: (context, state) {
      if (state is AssessmentCreated) {
        Navigator.pop(context, state.assessment);
      } else if (state is AssessmentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    },
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          ElevatedButton(
            onPressed: _create,
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
```

### Pattern 4: Real-time Score Preview

```dart
class AssessmentForm extends StatefulWidget {
  @override
  State<AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<AssessmentForm> {
  final answers = <String, dynamic>{};
  
  void _updateAnswer(String questionId, String answer) {
    setState(() => answers[questionId] = answer);
    
    // Recalculate score
    context.read<AssessmentBloc>().add(
      CalculateScoreEvent(
        assessmentId: widget.assessmentId,
        answers: answers,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Questions
        ...questions.map((q) =>
          Checkbox(
            onChanged: (selected) =>
              _updateAnswer(q.questionId, selected.toString()),
          ),
        ),
        // Score preview
        BlocBuilder<AssessmentBloc, AssessmentState>(
          builder: (context, state) {
            if (state is ScoreCalculated) {
              return Card(
                child: Column(
                  children: [
                    Text('Score: ${state.score}'),
                    Text('Status: ${state.leadStatus ?? 'Unknown'}'),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
```

---

## Best Practices

1. **Always check state type before accessing properties**
```dart
// Good
if (state is AssessmentsLoaded) {
  print(state.assessments.length);
}

// Bad - can throw exception
print(state.assessments.length); // state might not have assessments
```

2. **Use BlocListener for side effects**
```dart
// Good - Navigation, Snackbars, etc.
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    if (state is AssessmentCreated) {
      Navigator.pop(context);
    }
  },
)

// Bad - Don't put side effects in builder
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    if (state is AssessmentCreated) {
      Navigator.pop(context); // Can be called multiple times
    }
  },
)
```

3. **Combine Listener + Builder**
```dart
// Perfect pattern
Column(
  children: [
    BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        // Side effects: Navigation, Snackbars
        if (state is AssessmentSubmitted) {
          showSuccessSnackbar();
        }
      },
      child: BlocBuilder<AssessmentBloc, AssessmentState>(
        builder: (context, state) {
          // UI: Display data
          if (state is AssessmentLoaded) {
            return AssessmentCard(state.assessment);
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  ],
)
```

4. **Cache context data**
```dart
// Instead of loading multiple times
final context = await service.getAssessmentContext(id);
// Use context.questions, context.options, context.thresholds
```

5. **Handle errors gracefully**
```dart
if (state is AssessmentError) {
  return Center(
    child: Column(
      children: [
        const Icon(Icons.error),
        Text(state.message),
        ElevatedButton(
          onPressed: () => retry(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
```

---

## Debugging

Enable full logging:
```dart
// In main.dart
void setupLogging() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
    if (record.stackTrace != null) {
      print(record.stackTrace);
    }
  });
}
```

Print all BLoC transitions:
```dart
BlocListener<AssessmentBloc, AssessmentState>(
  listener: (context, state) {
    print('State: ${state.runtimeType}');
    print(state);
  },
)
```

---

## Performance Tips

1. Use `buildWhen` to prevent unnecessary rebuilds
```dart
BlocBuilder<AssessmentBloc, AssessmentState>(
  buildWhen: (prev, curr) =>
    curr is AssessmentLoaded && prev is! AssessmentLoaded,
  builder: (context, state) => ...,
)
```

2. Unsubscribe from streams when no longer needed
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = context.read<AssessmentBloc>().stream.listen(...);
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

3. Load only needed data
```dart
// Don't load if not needed
context.read<AssessmentBloc>().add(
  GetAssessmentEvent(
    assessmentId,
    loadRelated: false, // Skip questions/options
  ),
);
```

---

**For complete documentation, see:**
- [Developer Guide](DEVELOPER_GUIDE.md)
- [API Reference](../docs/ASSESSMENT_API_REFERENCE.md)
- [Service Layer Guide](SERVICE_LAYER_GUIDE.md)
