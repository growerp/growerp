# Example App Integration Guide

**Component**: growerp_assessment Package Integration  
**Package**: growerp_assessment  
**Version**: 1.9.0

## Overview

This guide explains how to integrate the `growerp_assessment` package into your Flutter application.

---

## Step 1: Add Dependency

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  growerp_assessment: ^1.9.0
```

Update dependencies:
```bash
flutter pub get
```

---

## Step 2: Generate Code

The package uses `build_runner` for code generation:

```bash
flutter pub run build_runner build
```

Or watch mode for development:
```bash
flutter pub run build_runner watch
```

---

## Step 3: Setup Dependency Injection

### Option A: Using GetIt (Recommended)

```dart
// lib/setup/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

void setupAssessmentServices() {
  // Create DIO instance
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.growerp.com',
    receiveTimeout: const Duration(seconds: 30),
    connectTimeout: const Duration(seconds: 30),
  ));
  
  // Add auth interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = getIt<String>(); // Get token from auth service
      options.headers['Authorization'] = 'Bearer $token';
      return handler.next(options);
    },
  ));
  
  // Register API client
  getIt.registerSingleton<AssessmentApiClient>(
    AssessmentApiClient(dio),
  );
  
  // Register logger
  getIt.registerSingleton<Logger>(Logger());
  
  // Register repository
  getIt.registerSingleton<AssessmentRepository>(
    AssessmentRepository(
      apiClient: getIt<AssessmentApiClient>(),
      logger: getIt<Logger>(),
    ),
  );
  
  // Register service
  getIt.registerSingleton<AssessmentService>(
    AssessmentService(
      repository: getIt<AssessmentRepository>(),
      logger: getIt<Logger>(),
    ),
  );
  
  // Register BLoC
  getIt.registerSingleton<AssessmentBloc>(
    AssessmentBloc(
      repository: getIt<AssessmentRepository>(),
      logger: getIt<Logger>(),
    ),
  );
}
```

In `main.dart`:
```dart
void main() {
  setupAssessmentServices();
  runApp(const MyApp());
}
```

### Option B: Using Provider

```dart
// lib/setup/providers.dart
import 'package:provider/provider.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

List<ChangeNotifierProvider> getAssessmentProviders() {
  return [
    Provider(
      create: (_) => AssessmentApiClient(
        Dio(BaseOptions(
          baseUrl: 'https://api.growerp.com',
        )),
      ),
    ),
    ProxyProvider<AssessmentApiClient, AssessmentRepository>(
      create: (context) => AssessmentRepository(
        apiClient: context.read(),
        logger: Logger(),
      ),
      update: (context, apiClient, previous) =>
        AssessmentRepository(
          apiClient: apiClient,
          logger: Logger(),
        ),
    ),
    ProxyProvider<AssessmentRepository, AssessmentBloc>(
      create: (context) => AssessmentBloc(
        repository: context.read(),
        logger: Logger(),
      ),
      update: (context, repository, previous) =>
        AssessmentBloc(
          repository: repository,
          logger: Logger(),
        ),
    ),
  ];
}
```

In `main.dart`:
```dart
void main() {
  runApp(
    MultiProvider(
      providers: getAssessmentProviders(),
      child: const MyApp(),
    ),
  );
}
```

### Option C: Using BLoC Provider (GrowERP Pattern)

```dart
// Follow GrowERP's `getCoreBlocProviders()` pattern
// Add to your application's provider setup

List<BlocProvider> getAssessmentBlocProviders() {
  return [
    BlocProvider(
      create: (_) => AssessmentBloc(
        repository: AssessmentRepository(
          apiClient: _createApiClient(),
          logger: Logger(),
        ),
        logger: Logger(),
      ),
    ),
  ];
}

AssessmentApiClient _createApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.growerp.com',
  ));
  // Add interceptors...
  return AssessmentApiClient(dio);
}
```

---

## Step 4: Create Assessment Screen

### Basic Assessment List Screen

```dart
// lib/screens/assessment_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

class AssessmentListScreen extends StatefulWidget {
  const AssessmentListScreen({Key? key}) : super(key: key);
  
  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }
  
  void _loadAssessments() {
    context.read<AssessmentBloc>().add(
      ListAssessmentsEvent(
        start: _currentPage * 20,
        limit: 20,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
          ),
        ],
      ),
      body: BlocBuilder<AssessmentBloc, AssessmentState>(
        builder: (context, state) {
          if (state is AssessmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is AssessmentsLoaded) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.assessments.length,
                    itemBuilder: (context, index) {
                      final assessment = state.assessments[index];
                      return ListTile(
                        title: Text(assessment.assessmentName),
                        subtitle: Text(assessment.description ?? ''),
                        onTap: () => _viewAssessment(assessment),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editAssessment(assessment),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _currentPage--);
                            _loadAssessments();
                          },
                          child: const Text('Previous'),
                        ),
                      Text('Page ${_currentPage + 1} of ${state.totalCount ~/ 20 + 1}'),
                      if ((_currentPage + 1) * 20 < state.totalCount)
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _currentPage++);
                            _loadAssessments();
                          },
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
          
          if (state is AssessmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  Text(state.message),
                  ElevatedButton(
                    onPressed: _loadAssessments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  void _viewAssessment(Assessment assessment) {
    context.read<AssessmentBloc>().add(
      GetAssessmentEvent(assessment.assessmentId),
    );
    Navigator.of(context).pushNamed('/assessment/detail', arguments: assessment);
  }
  
  void _editAssessment(Assessment assessment) {
    Navigator.of(context).pushNamed('/assessment/edit', arguments: assessment);
  }
  
  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateAssessmentDialog(
        onCreated: (assessment) {
          _loadAssessments();
        },
      ),
    );
  }
}
```

---

## Step 5: Create Assessment Submit Flow

### Three-Step Assessment Screen

```dart
// lib/screens/assessment_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

class AssessmentFormScreen extends StatefulWidget {
  final String assessmentId;
  
  const AssessmentFormScreen({
    Key? key,
    required this.assessmentId,
  }) : super(key: key);
  
  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  int _currentStep = 0;
  late AssessmentContext _context;
  
  // Step 1: Lead capture
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  
  // Step 2: Questions
  final Map<String, dynamic> _answers = {};
  
  // Step 3: Results
  late AssessmentResult _result;
  
  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }
  
  Future<void> _loadAssessment() async {
    context.read<AssessmentBloc>().add(
      GetAssessmentEvent(widget.assessmentId),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
      body: BlocListener<AssessmentBloc, AssessmentState>(
        listener: (context, state) {
          if (state is AssessmentLoaded) {
            _context = AssessmentContext(
              assessment: state.assessment,
              questions: state.questions ?? [],
              options: {}, // Load from state
              thresholds: state.thresholds ?? [],
            );
          } else if (state is AssessmentSubmitted) {
            _result = state.result;
            setState(() => _currentStep = 2);
          } else if (state is AssessmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AssessmentBloc, AssessmentState>(
          builder: (context, state) {
            if (state is AssessmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              steps: [
                // Step 1: Lead Capture
                Step(
                  title: const Text('Your Information'),
                  content: _buildLeadCaptureStep(),
                  isActive: _currentStep >= 0,
                ),
                // Step 2: Assessment Questions
                Step(
                  title: const Text('Assessment'),
                  content: _buildQuestionsStep(state),
                  isActive: _currentStep >= 1,
                ),
                // Step 3: Results
                Step(
                  title: const Text('Results'),
                  content: _buildResultsStep(),
                  isActive: _currentStep >= 2,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildLeadCaptureStep() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyController,
          decoration: const InputDecoration(labelText: 'Company'),
        ),
      ],
    );
  }
  
  Widget _buildQuestionsStep(AssessmentState state) {
    if (state is! AssessmentLoaded) {
      return const CircularProgressIndicator();
    }
    
    final questions = state.questions ?? [];
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${question.questionSequence}: ${question.questionText}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                // Show options based on question type
                if (question.questionType == 'multiselect')
                  _buildMultiSelectOptions(question)
                else if (question.questionType == 'text')
                  _buildTextInput(question)
                else
                  _buildScoreInput(question),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMultiSelectOptions(AssessmentQuestion question) {
    // Get options from context
    final options = _context.options[question.questionId] ?? [];
    
    return Column(
      children: options.map((option) {
        final isSelected = _answers[question.questionId] == option.optionId;
        
        return CheckboxListTile(
          title: Text(option.optionText),
          subtitle: Text('${option.optionScore} points'),
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              _answers[question.questionId] = option.optionId;
            });
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildTextInput(AssessmentQuestion question) {
    return TextField(
      decoration: const InputDecoration(labelText: 'Your answer'),
      onChanged: (value) {
        _answers[question.questionId] = value;
      },
    );
  }
  
  Widget _buildScoreInput(AssessmentQuestion question) {
    return Slider(
      min: 0,
      max: 10,
      value: (_answers[question.questionId] ?? 0).toDouble(),
      onChanged: (value) {
        setState(() {
          _answers[question.questionId] = value.toInt();
        });
      },
    );
  }
  
  Widget _buildResultsStep() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Your Score',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _result.score.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lead Status: ${_result.leadStatus}',
                  style: TextStyle(
                    fontSize: 18,
                    color: _getStatusColor(_result.leadStatus),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check),
          label: const Text('Done'),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'hot':
        return Colors.red;
      case 'warm':
        return Colors.orange;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate lead capture
      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Submit assessment
      context.read<AssessmentBloc>().add(
        SubmitAssessmentEvent(
          assessmentId: widget.assessmentId,
          answers: _answers,
          respondentName: _nameController.text,
          respondentEmail: _emailController.text,
          respondentPhone: _phoneController.text,
          respondentCompany: _companyController.text,
        ),
      );
    }
  }
  
  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }
}
```

---

## Step 6: Add Routes

```dart
// lib/main.dart or routes.dart
import 'package:flutter/material.dart';

class AppRoutes {
  static const assessmentList = '/assessments';
  static const assessmentForm = '/assessments/:id';
  static const assessmentDetail = '/assessments/:id/detail';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case assessmentList:
        return MaterialPageRoute(
          builder: (_) => const AssessmentListScreen(),
        );
      case assessmentForm:
        final assessmentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AssessmentFormScreen(
            assessmentId: assessmentId,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
```

In `main.dart`:
```dart
void main() {
  setupAssessmentServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.assessmentList,
    );
  }
}
```

---

## Step 7: Integration with Existing App

### If using GrowERP Admin App

Add to your admin app's dependency setup:

```dart
// In admin app's get_core_bloc_providers or equivalent
List<BlocProvider> getAdminBlocProviders() {
  return [
    // Existing providers...
    
    // Add assessment
    BlocProvider(
      create: (_) => AssessmentBloc(...),
    ),
  ];
}
```

Add navigation menu item:

```dart
ListTile(
  title: const Text('Assessments'),
  leading: const Icon(Icons.assessment),
  onTap: () => Navigator.pushNamed(context, '/assessments'),
),
```

---

## Step 8: Testing

### Widget Test Example

```dart
// test/widgets/assessment_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

class MockAssessmentBloc extends Mock implements AssessmentBloc {}

void main() {
  group('AssessmentListScreen', () {
    late MockAssessmentBloc mockBloc;
    
    setUp(() {
      mockBloc = MockAssessmentBloc();
      when(() => mockBloc.state).thenReturn(AssessmentInitial());
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(AssessmentInitial()),
      );
    });
    
    testWidgets('displays loading indicator when loading', (tester) async {
      when(() => mockBloc.state).thenReturn(AssessmentLoading());
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AssessmentBloc>.value(
            value: mockBloc,
            child: const AssessmentListScreen(),
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('displays assessments when loaded', (tester) async {
      final assessments = [
        Assessment(
          assessmentId: '1',
          pseudoId: 'pseudo_1',
          assessmentName: 'Test Assessment',
          ownerPartyId: 'owner',
          status: 'ACTIVE',
          createdDate: DateTime.now(),
        ),
      ];
      
      when(() => mockBloc.state).thenReturn(
        AssessmentsLoaded(
          assessments: assessments,
          page: 0,
          pageSize: 20,
          totalCount: 1,
        ),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AssessmentBloc>.value(
            value: mockBloc,
            child: const AssessmentListScreen(),
          ),
        ),
      );
      
      expect(find.text('Test Assessment'), findsOneWidget);
    });
  });
}
```

---

## Troubleshooting

### Build Generation Issues

```bash
# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Dependency Issues

```bash
flutter pub get
flutter pub upgrade
```

### State Not Updating

Ensure you're using `BlocBuilder` or `BlocListener`:
```dart
// Good
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) => ...,
)

// Bad - won't update
final state = context.read<AssessmentBloc>().state;
```

---

**For more information, see:**
- [Developer Guide](DEVELOPER_GUIDE.md)
- [BLoC Usage Guide](BLoC_USAGE_GUIDE.md)
- [Service Layer Guide](SERVICE_LAYER_GUIDE.md)
- [Repository Pattern Guide](REPOSITORY_PATTERN_GUIDE.md)
